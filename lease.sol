pragma solidity 0.8.0 < 0.9.0;

contract Lease {
    
    uint32 assetIdentifier;
    uint32 assetValue;
    uint32 lifespan;
    uint32 periodicity;
    uint32 fineRate;
    uint32 terminationFine;
    uint32 duration;
    
    
    struct Lessor {
        address payable lessor; 
    }
    
    struct Lessee {
        address payable lessee; 
    }
    
    struct InsuranceCompany {
        address payable insurer; 
        uint32 interestRate;
    }
    
    Lessor[1] public lessors;
    uint32 numLessors;
    Lessee[1] public lessees;
    uint32 numLessees;
    InsuranceCompany[1] public insurers;
    uint32 numInsurers;
    
    function lessorInput(uint32 assetIdentifier, uint32 assetValue, uint32 lifespan, 
        uint32 periodicity, uint32 fineRate, uint32 terminationFine) public returns (bool) {
            
        require(numLessors != 1); //só entra caso seja o primeiro lessor
        lessors[numLessors].lessor = payable(msg.sender); //atribui o lessor
        numLessors = numLessors + 1; //incrementa o numLessors
        
        //faz as atribuições 
        assetIdentifier = assetIdentifier;
        assetValue = assetValue;
        lifespan = lifespan;
        periodicity = periodicity;
        fineRate = fineRate;
        terminationFine = terminationFine;
        
        //mudar estado
        //fazer return
    }
    
    function insuranceInput(uint32 interestRate) public returns (bool) {
            
        require(numInsurers != 1); //só entra caso seja o primeiro insurer
        insurers[numInsurers].insurer = payable(msg.sender); //atribui o insurer
        numInsurers = numInsurers + 1; //incrementa o numInsurers
        
        //faz as atribuições 
        interestRate = interestRate;

        //mudar estado
        //fazer return
    }
    
    function lesseeInput(uint32 duration) public returns (bool) {
            
        require(numLessees != 1); //só entra caso seja o primeiro lessee
        lessees[numLessees].lessee = payable(msg.sender); //atribui o lessee
        numLessees = numLessees + 1; //incrementa o numLessees
        
        //faz as atribuições 
        duration = duration;

        //mudar estado
        //fazer return
    }
    
    // monthlyInstallment = assetValue
    
    
}