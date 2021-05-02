pragma solidity >= 0.8.0 < 0.9.0;

contract Lease {
    
    //parâmetros do contrato
    uint32 assetIdentifier;
    uint32 assetValue;
    uint32 lifespan;
    uint32 periodicity;
    uint32 fineRate;
    uint32 terminationFine;
    uint32 interestRate;
    uint32 duration;
    uint32 monthlyInstallment;
    uint32 monthlyInsurance;
    uint32 rental;
    uint residualValue;
    uint32 numPaidMonthlyInstallmentsOrRentals;
    uint startTime;
    uint currentCycle;
    uint lastRentalCycle;
    
    
    //entidades principais
    address payable lessor; 
    address payable lessee; 
    address payable insuranceCompany;
    
    //entidade abstrata que fica com os tokens que o lessor depois pode fazer withdraw
    address payable smartContract;
    
    
    //map com os endereços e os respetivos saldos de cada entidade
    mapping (address => uint) public balances;
    
    //map com o número do ciclo e com a informação se a renda foi ou não paga
    mapping (uint => bool) public paidRentals; 
    
    
    //eventos que poderão ser gerados
    event NewOwner(address newOwner, uint32 assetIdentifier);
    event AssetDestroyed(address insuranceCompany, uint32 assetIdentifier);
    
    
    //enumerado que define os estados do smart contract (o estado INIT é meramente um estado lógico inicial, 
    //de modo a que a primeira função (lessorInput) só corra nesse estado)
    enum State { INIT, CREATED, SIGNED, VALID, TERMINATED }
    State public state;
    
    
    //modifier que permite saber em que estado é que está e é usado de modo a ser chamado antes da 
    //execução de determinadas funções que só podem correr em determinados estados
    modifier inState(State s) {
        require(state == s, "Not in the proper state");
        _;
    }
    
    
    //construtor do contrato, que é chamado aquando do deploy
    constructor() public {
        
        state = State.INIT; //estado lógico inicial
        
        //atribuição fixa de endereços para as entidades (podem-se mudar os endereços)
        lessor = payable(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
        insuranceCompany = payable(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);
        lessee = payable(0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db);
        smartContract = payable(0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB);
        
        //inicialização de alguns parâmetros
        numPaidMonthlyInstallmentsOrRentals = 0;
        currentCycle = 1; //o primeiro ciclo é sempre 1
        lastRentalCycle = 0; //abstração para manter track do último ciclo em que a renda foi paga
        startTime = 0; //esta variável vai determinar o tempo de cada ciclo

    }
    
    
    //função 1
    function lessorInput(uint32 assetIdentifier, uint32 assetValue, uint32 lifespan, 
        uint32 periodicity, uint32 fineRate, uint32 terminationFine) inState(State.INIT) public returns (bool) {
        require(payable(msg.sender) == lessor); //tem que ser o lessor a definir estes dados

        //faz as atribuições 
        setLessorInput(assetIdentifier, assetValue, lifespan, periodicity, fineRate, terminationFine);
        setMonthlyInstallment();
        
        //passa o estado para CREATED
        state = State.CREATED;
        return true;
    }
    
    
    //função 2
    function insuranceInput(uint32 interestRate) inState(State.CREATED) public returns (bool) {
        require(payable(msg.sender) == insuranceCompany); //tem que ser a insuranceCompany a definir o interestRate  
        
        //faz as atribuições 
        setInsuranceCompanyInput(interestRate);
        
        //passa o estado para SIGNED
        state = State.SIGNED;
        return true;
    }
    
    
    //função 3
    function lesseeInput(uint32 duration) inState(State.SIGNED) public returns (bool) {
        require(payable(msg.sender) == lessee);  //tem que ser o lessee a definir a duration
        
        //faz as atribuições 
        setLesseeInput(duration);
        setMonthlyInsurance(); 
        setRental();
        setResidualValue();
        
        //passa o estado para VALID
        state = State.VALID;
        
        //inicializa o tempo
        startContractDuration();

        return true;
    }
    
    
    //função para avançar o ciclo a cada 3 minutos
    //deve ser executada manualmente (e só executa no estado VALID)
    function advanceCycle() inState(State.VALID) public returns (bool) {
        require(block.timestamp >= startTime + 45 seconds); //verifica se já passaram 3 minutos desde o último startTime
        require(currentCycle <= duration);
        startTime = block.timestamp; //atualiza o startTime
        currentCycle++; //incrementa o ciclo
        if(checkIfHasPaidTheLastTwoRentals()) { //verifica se o lessee já pagou as duas últimas rendas antes de avançar o ciclo
            return true;
        }
        //se não tiver pago, o smart contract fica TERMINATED
        state = State.TERMINATED;
        return false;
    }


    //função 4
    function payRental() inState(State.VALID) payable public returns (bool) {
        require(payable(msg.sender) == lessee); //só é executada pelo lessee
        require(balances[lessee] >= rental); //só é executada se o lessee tiver mais tokens que o preço da renda
        require(currentCycle > lastRentalCycle && numPaidMonthlyInstallmentsOrRentals < duration); //só executa se estiver num ciclo maior que o último e se o número de rendas
        //ou monthly monthlyInstallments pagos não exceder a duração 
        
        //este if implementa a função 8
        if(currentCycle > 1) {
            if(!paidRentals[currentCycle - 1]) {
                require(balances[lessee] >= (2*rental) + fineRate);
                //paga a renda passada e o fine rate (a atual já pagará fora do if)
                balances[lessee] -= monthlyInstallment; //decrementa o monthlyInstallment do lessee
                balances[smartContract] += monthlyInstallment; //mete-o no smart contract
                balances[lessee] -= monthlyInsurance; //decrementa o monthlyInsurance do lessee
                balances[insuranceCompany] += monthlyInsurance; //mete-o na insuranceCompany
                paidRentals[currentCycle - 1] = true; //indica que pagou a renda passada
                balances[lessee] -= fineRate; //paga a fine rate
                numPaidMonthlyInstallmentsOrRentals++; //incrementa o numero de rendas/monthly installments pagos
            }
        }
        balances[lessee] -= monthlyInstallment; //decrementa o monthlyInstallment do lessee
        balances[smartContract] += monthlyInstallment; //mete-o no smart contract
        balances[lessee] -= monthlyInsurance; //decrementa o monthlyInsurance do lessee
        balances[insuranceCompany] += monthlyInsurance; //mete-o na insuranceCompany
        paidRentals[currentCycle] = true; //indica que pagou a renda deste ciclo
        lastRentalCycle = currentCycle; //e indica que este foi a renda mais recente que pagou
        numPaidMonthlyInstallmentsOrRentals++; //incrementa o numero de rendas/monthly installments pagos
        return true;
    }
    
    
    //função 5
    //aqui não é preciso ser VALID, até porque o lessor pode receber tokens depois do asset ser destruído pela insuranceCompany
    function withdraw(uint amount) payable public returns (bool) {
        require(payable(msg.sender) == lessor); //só é chamado pelo lessor
        require(balances[smartContract] >= amount); //verifica se a entidade abstrata do smart contract tem uma quantia maior ou igual à pretendida 
        balances[smartContract] -= amount; //decrementa a quantia do smartContract
        balances[lessor] += amount; //mete no lessor
        return true;
    }
    
    
    //função 6
    function amortizeResidualValue(uint amount) inState(State.VALID) payable public returns (bool) {
        require(payable(msg.sender) == lessee); //só é chamado pelo lessee
        require(amount <= residualValue && residualValue >= 0); //o residualValue tem que ser maior que 0 (caso contrário nem faz sentido amortizar) e o amount tem que ser menor ou igual ao residualValue
        balances[lessee] -= amount; //o lessee perde a quantia que pagou 
        setNewResidualValue(amount); //atualiza-se o residualValue
        return true;
    }
    
    
    //função 7
    function liquidateLease() inState(State.VALID) payable public returns (bool) {
        require(payable(msg.sender) == lessee); //só é chamado pelo lessee
        require(balances[lessee] >= monthlyInstallment * (duration - numPaidMonthlyInstallmentsOrRentals)); //verifica se o lessee tem mais tokens que todos os monthlyInstallments restantes 
        require(numPaidMonthlyInstallmentsOrRentals < duration);
        balances[lessee] -= monthlyInstallment * (duration - numPaidMonthlyInstallmentsOrRentals); //decrementa o valor dos monthlyInstallments que faltam da carteira do lessee
        balances[smartContract] += monthlyInstallment * (duration - numPaidMonthlyInstallmentsOrRentals); //mete este valor no "saldo" do smart contract
        numPaidMonthlyInstallmentsOrRentals = duration; //iguala o número de monthlyInstallments pagos à duration
        return true;
    }
    
    
    //função 9
    function terminateLease() inState(State.VALID) payable public returns (bool) {
        require(payable(msg.sender) == lessee); //só é chamado pelo lessee
        
        //se estiver num ciclo > 1, paga a termination fine, caso contrário não paga nada
        if(currentCycle > 1) {
            require(balances[lessee] >= terminationFine); 
            balances[lessee] -= terminationFine;
        }
        
        //atualiza o estado para TERMINATED
        state = State.TERMINATED;
        return true;
    }
    
    
    //funções 10 - 11
    function finishLeaseLiquidation() inState(State.VALID) public returns (bool) {
        require(payable(msg.sender) == lessee); //só é chamado pelo lessee
        
        //verifica se já pagou as rendas e o valor residual, caso contrário, o evento nem é emitido
        if(numPaidMonthlyInstallmentsOrRentals == duration && residualValue == 0) {
            emit NewOwner(msg.sender, assetIdentifier); //emite o evento a informar que o lessee é o novo dono do asset
        }
        
        //de qualquer maneira, atualiza o estado para TERMINATED
        state = State.TERMINATED;
        return true;
    }
     
        
    //função 12
    function destroyAsset() inState(State.VALID) payable public returns (bool) {
        require(payable(msg.sender) == insuranceCompany); //só é chamado pela insuranceCompany
        require(balances[insuranceCompany] >= assetValue); //tem que ter um saldo maior ou igual ao valor do asset
        balances[insuranceCompany] -= assetValue; //decrementa o assetValue da sua balance
        balances[smartContract] += assetValue; //mete no smartContract, uma vez que pode ser withdrawn pelo lessor
        emit AssetDestroyed (msg.sender, assetIdentifier); //emite o evento para informar que o asset foi destruído pela companhia
        state = State.TERMINATED; //atualiza o estado para TERMINATED
        return true;
    }
    
    
    //função que é chamada a cada ciclo e que verifica se o lessee pagou as duas últimas rendas (equivale à função 13)
    function checkIfHasPaidTheLastTwoRentals() private returns (bool){
        
        //pode retornar true se estivermos num ciclo inferior a 3 (já que o ciclo inicial é 1 e só basta entrar aqui se não tiver pago as duas últimas rendas)
        if(currentCycle >= 3) {
            //verifica se pagou as duas últimas rendas
            if(!paidRentals[currentCycle-1] && !paidRentals[currentCycle-2]) {
                
                //se não pagou, retorna false para a função da alteração de ciclo, que vai atualizar o estado para TERMINATED
                return false;
            }
        }
        return true; 
    }
    
    
    //função que permite inserir créditos nos balances das entidades (o amount é definido com o msg.value)
    function addTokens(address entity) payable public{
        balances[entity] += msg.value;
    }
    
    
    //função para obter o valor do monthlyInstallment
    function getMonthlyInstallment() public view returns (uint32) {
        return monthlyInstallment;
    }
    
    
    //função para obter o valor do monthlyInsurance
    function getMonthlyInsurance() public view returns (uint32) {
        return monthlyInsurance;
    }
    
    
    //função para obter o valor da renda mensal
    function getRental() public view returns (uint32) {
        return rental;
    }
    
    
    //função para obter o valor atual do residualValue
    function getResidualValue() public view returns (uint) {
        return residualValue;
    }
    
    
    //função para obter o número de rendas ou monthlyInstallments pagos
    function getPaidMonthlyInstallmentsOrRentals() public view returns (uint) {
        return numPaidMonthlyInstallmentsOrRentals;
    }
    
    
    //função para obter o ciclo atual
    function getCurrentCycle() public view returns (uint) {
        return currentCycle;
    }
    
    
    //função para atribuir os parâmetros passados pelo lessor
    function setLessorInput(uint32 a, uint32 b, uint32 c, uint32 d, uint32 e, uint32 f) private {
        assetIdentifier = a;
        assetValue = b;
        lifespan = c;
        periodicity = d;
        fineRate = e;
        terminationFine = f;
    }
    
    
    //função para atribuir o parâmetro passado pela insuranceCompany
    function setInsuranceCompanyInput(uint32 a) private {
        interestRate = a;
    }
    
    
    //função para atribuir o parâmetro passado pelo lessee
    function setLesseeInput(uint32 a) private {
        duration = a;
    }
    
    
    //função para definir e calcular o monthlyInstallment
    function setMonthlyInstallment() private {
        monthlyInstallment = assetValue/lifespan;
    }
    
    
    //função para definir e calcular o monthlyInsurance
    function setMonthlyInsurance() private {
        monthlyInsurance = (assetValue*interestRate)/duration;
    }
    
    
    //função para definir e calcular a renda
    function setRental() private {
        rental = monthlyInstallment + monthlyInsurance;
    }
    
    
    //função para definir e calcular o valor residual
    function setResidualValue() private {
        residualValue = assetValue - (monthlyInstallment*duration);
    }
    
    
    //função para atualizar o valor residualValue
    function setNewResidualValue(uint amount) private {
        residualValue -= amount;
    }
    
    
    //função para iniciar o clock (só é chamada depois do contrato estar VALID)
    function startContractDuration() private {
        startTime = block.timestamp;
    }
    
    
    //função para obter o número de segundos que já passaram desde que estamos num ciclo
    function getSecondsPast() public view returns (uint) {
        return block.timestamp - startTime;
    }

    //EXEMPLO DE INPUT INICIAL:
    
    //0,1000,5,2,10,20 (lessor)
    //5 (insurer)
    //2 (lessee)
    //0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db (lessee)
    
}