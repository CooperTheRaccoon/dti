pragma solidity >= 0.8.0 < 0.9.0;

contract Lease {
    
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
    uint32 numPaidMonthlyInstallments;
    uint startTime;
    uint numCycles;
    uint lastNumCycle;
    address payable lessor; 
    address payable lessee; 
    address payable insuranceCompany;
    address payable smartContract;
    
    mapping (address => uint) public balances;
    mapping (uint => bool) public paidRentals; 

    event NewOwner(address newOwner, uint32 assetIdentifier);
    event AssetDestroyed(uint32 assetIdentifier, address insuranceCompany);
    
    enum State { INIT, CREATED, SIGNED, VALID, TERMINATED }
    
    State public state;
    
    modifier inState(State s) {
        require(state == s, "Not in the proper state");
        _;
    }
    
    //modifier hasPassed3Minutes() {
    //    require (block.timestamp >= startTime + 30 seconds);
    //    startTime = block.timestamp;
    //    numCycles++;
    //    _;
    //}

    constructor() public {
        
        state = State.INIT; //estado lógico inicial
        
        //atribuição fixa de endereços para as entidades (podem-se mudar os endereços)
        
        lessor = payable(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
        insuranceCompany = payable(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);
        lessee = payable(0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db);
        smartContract = payable(0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB);
        
        numPaidMonthlyInstallments = 0;
        numCycles = 1;
        lastNumCycle = 0;
        startTime = 0;

    }
    
    function lessorInput(uint32 assetIdentifier, uint32 assetValue, uint32 lifespan, 
        uint32 periodicity, uint32 fineRate, uint32 terminationFine) inState(State.INIT) public returns (bool) {
        
        require(payable(msg.sender) == lessor);

        //faz as atribuições 
        
        setLessorInput(assetIdentifier, assetValue, lifespan, periodicity, fineRate, terminationFine);
        
        setMonthlyInstallment();
        
        state = State.CREATED;
        
        return true;
    }
    
    function insuranceInput(uint32 interestRate) inState(State.CREATED) public returns (bool) {
        
        require(payable(msg.sender) == insuranceCompany);        
        
        //faz as atribuições 
        
        setInsurerInput(interestRate);
        
        state = State.SIGNED;

        return true;
    }
    
    function lesseeInput(uint32 duration) inState(State.SIGNED) public returns (bool) {
        require(payable(msg.sender) == lessee);
        
        //faz as atribuições 
        setLesseeInput(duration);
        
        setMonthlyInsurance(); 
        
        setRental();
        
        setResidualValue();
        
        state = State.VALID;
        
        startContractDuration();

        return true;
    }
    
    
    function advanceCycle() inState(State.VALID) public returns (bool) {
        require(block.timestamp >= startTime + 45 seconds);
        startTime = block.timestamp;
        numCycles++;
        return true;
    }

    
    function payRental() inState(State.VALID) payable public returns (bool) {
        
        //vai ter que verificar se pode ser chamado
        require(payable(msg.sender) == lessee);
        require(balances[lessee] >= rental);
        require(numCycles > lastNumCycle && numCycles <= duration);
        
        balances[lessee] -= monthlyInstallment;
        balances[smartContract] += monthlyInstallment;
        balances[lessee] -= monthlyInsurance;
        balances[insuranceCompany] += monthlyInsurance;
        paidRentals[numCycles] = true;
        lastNumCycle = numCycles;
        numPaidMonthlyInstallments++;
        return true;
    }
    
    
    function withdraw(uint amount) inState(State.VALID) payable public returns (bool) {
        
        //vai ter que verificar se pode ser chamado
        require(payable(msg.sender) == lessor);
        require(balances[smartContract] >= amount);
        balances[smartContract] -= amount;
        balances[lessor] += amount;
        return true;
    }
    
    function amortizeResidualValue() inState(State.VALID) payable public returns (bool) {
        
        //vai ter que verificar se pode ser chamado
        require(payable(msg.sender) == lessee);
        require(msg.value <= residualValue && residualValue >= 0);
        balances[lessee] -= msg.value;
        //atualiza-se
        setNewResidualValue(msg.value);
        return true;
    }
    
    function liquidateLease() inState(State.VALID) payable public returns (bool) {
        
        //vai ter que verificar se pode ser chamado
        require(payable(msg.sender) == lessee);
        require(balances[lessee] >= monthlyInstallment * (duration - numPaidMonthlyInstallments));
        balances[lessee] -= monthlyInstallment * (duration - numPaidMonthlyInstallments);
        balances[smartContract] += monthlyInstallment * (duration - numPaidMonthlyInstallments);
        numPaidMonthlyInstallments = duration;
        return true;
    }
    
    function addTokens(address entity) payable public{
        balances[entity] += msg.value;
    }
    
    
    function getMonthlyInstallment() public view returns (uint32) {
        return monthlyInstallment;
    }
    
    function getMonthlyInsurance() public view returns (uint32) {
        return monthlyInsurance;
    }
    
    function getRental() public view returns (uint32) {
        return rental;
    }
    
    function getResidualValue() public view returns (uint) {
        return residualValue;
    }
    
    function getNumPaidMonthlyInstallments() public view returns (uint) {
        return numPaidMonthlyInstallments;
    }
    
    function getNumCycles() public view returns (uint) {
        return numCycles;
    }
    
    function setLessorInput(uint32 a, uint32 b, uint32 c, uint32 d, uint32 e, uint32 f) private {
        assetIdentifier = a;
        assetValue = b;
        lifespan = c;
        periodicity = d;
        fineRate = e;
        terminationFine = f;
    }
    
    function setInsurerInput(uint32 a) private {
        interestRate = a;
    }
    
    function setLesseeInput(uint32 a) private {
        duration = a;
    }
    
    function setMonthlyInstallment() private {
        monthlyInstallment = assetValue/lifespan;
    }
    
    function setMonthlyInsurance() private {
        monthlyInsurance = (assetValue*interestRate)/duration;
    }
    
    function setRental() private {
        rental = monthlyInstallment + monthlyInsurance;
    }
    
    function setResidualValue() private {
        residualValue = assetValue - (monthlyInstallment*duration);
    }
    
    function setNewResidualValue(uint amount) private {
        residualValue -= amount;
    }
    
    function startContractDuration() private {
        startTime = block.timestamp;
    }
    
    function getSecondsPast() public view returns (uint) {
        return block.timestamp - startTime;
    }


    //0,1000,5,2,10,20 (lessor)
    //5 (insurer)
    //2 (lessee)
    //0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db (lessee)
    
}