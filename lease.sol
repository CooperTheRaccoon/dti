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
    uint32 rental;
    
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
        
        setLessorInput(assetIdentifier, assetValue, lifespan, periodicity, fineRate, terminationFine);
        
        setMonthlyInstallment();
        
        state = State.CREATED;
        
        return true;
    }
    
    function insuranceInput(uint32 interestRate) inState(State.CREATED) public returns (bool) {
        require(numInsurers != 1 && msg.sender != lessors.lessor); //só entra caso seja o primeiro insurer e se for diferente do lessor
        insurers.insurer = payable(msg.sender); //atribui o insurer
        numInsurers = numInsurers + 1; //incrementa o numInsurers
        
        //faz as atribuições 
        setInsurerInput(interestRate);
        
        state = State.SIGNED;

        return true;
    }
    
    function lesseeInput(uint32 duration) inState(State.SIGNED) public returns (bool) {
        require(numLessees != 1 && msg.sender != insurers.insurer && msg.sender != lessors.lessor); //só entra caso seja o primeiro lessee e se for diferente das outras entidades
        lessees.lessee = payable(msg.sender); //atribui o lessee
        numLessees = numLessees + 1; //incrementa o numLessees
        
        //faz as atribuições 
        setLesseeInput(duration);
        
        setMonthlyInsurance(); 
        
        setRental();
        
        state = State.VALID;

        return true;
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
    
    //0,1000,5,2,10,20 (lessor)
    //5 (insurer)
    //2 (lessee)
    
}