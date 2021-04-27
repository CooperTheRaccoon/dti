pragma solidity 0.8.0 < 0.9.0;

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
    
    struct Lessor {
        address payable lessor; 
    }
    
    struct Lessee {
        address payable lessee; 
    }
    
    struct InsuranceCompany {
        address payable insurer; 
    }
    
    Lessor public lessors;
    uint32 numLessors;
    Lessee public lessees;
    uint32 numLessees;
    InsuranceCompany public insurers;
    uint32 numInsurers;
    
    
    enum State { INIT, CREATED, SIGNED, VALID, TERMINATED }
    
    State public state;
    
    modifier inState(State s) {
        require(state == s, "Not in the proper state");
        _;
    }
    
    constructor() public {
        state = State.INIT;
        numLessors = 0;
        numLessees = 0;
        numInsurers = 0;
    }
    
    function lessorInput(uint32 assetIdentifier, uint32 assetValue, uint32 lifespan, 
        uint32 periodicity, uint32 fineRate, uint32 terminationFine) inState(State.INIT) public returns (bool) {
        
        //fazer o check de não ser o mesmo gajo que o lessee ou o insurer
        require(numLessors != 1); //só entra caso seja o primeiro lessor
        lessors.lessor = payable(msg.sender); //atribui o lessor
        numLessors = numLessors + 1; //incrementa o numLessors
        
        //faz as atribuições 
        assetIdentifier = assetIdentifier;
        assetValue = assetValue;
        lifespan = lifespan;
        periodicity = periodicity;
        fineRate = fineRate;
        terminationFine = terminationFine;
        
        state = State.CREATED;
        
        monthlyInstallment = assetValue/lifespan; //já se pode atribuir o monthlyInstallment
        
        return true;
    }
    
    function insuranceInput(uint32 interestRate) inState(State.CREATED) public returns (bool) {
        require(numInsurers != 1 && msg.sender != lessors.lessor); //só entra caso seja o primeiro insurer e se for diferente do lessor
        insurers.insurer = payable(msg.sender); //atribui o insurer
        numInsurers = numInsurers + 1; //incrementa o numInsurers
        
        //faz as atribuições 
        interestRate = interestRate;
        
        state = State.SIGNED;

        return true;
    }
    
    function lesseeInput(uint32 duration) inState(State.SIGNED) public returns (bool) {
        require(numLessees != 1 && msg.sender != insurers.insurer && msg.sender != lessors.lessor); //só entra caso seja o primeiro lessee e se for diferente das outras entidades
        lessees.lessee = payable(msg.sender); //atribui o lessee
        numLessees = numLessees + 1; //incrementa o numLessees
        
        //faz as atribuições 
        duration = duration;

        state = State.VALID;
        
        monthlyInsurance = (assetValue*interestRate)/duration; //já se pode atribuir o monthlyInsurance (está a dar mal)

        return true;
    }
    
    
    function getMonthlyInstallment() public view returns (uint32) {
        return monthlyInstallment;
    }
    
    function getMonthlyInsurance() public view returns (uint32) {
        return monthlyInsurance;
    }
    
    //0,1000,5,2,10,20 (lessor)
    //5 (insurer)
    //2 (lessee)
    
    
    
}