Membros do grupo:
- João Preto (51046)
- Daniel Ângelo (51107)
- Guilherme Nunes (51594)


Instruções para fazer deploy do contrato: 
1 - Fazer compile do código do ficheiro lease.sol
2 - Na tab do Deploy & Run Transactions, selecionar o JavaScriptVM
3 - Colocar como gas limit mínimo 3267025
4 - Fazer deploy do contrato


Instruções para testar algumas funcionalidades do contrato:
1 - Depois de se fazer deploy, podem-se selecionar 3 endereços que contenham uma quantidade elevada de ether
2 - Os endereços selecionados podem corresponder desde logo às entidades inicializadas no construtor do contrato, caso
contrário, pode-se mudar e recompilar o contrato
3 - Para definir os parâmetros iniciais da função 1, temos que selecionar o endereço correspondente ao Lessor e 
inserir 6 argumentos correspondentes ao asset identifier, asset value, lifespan, periodicity (em minutos), fine rate e termination rate, 
que podem ser por exemplo "0,1000,5,3,10,20" (todos uint32)
4 - Para definir os parâmetros iniciais da função 2, temos que selecionar o endereço correspondente à Insurance Company e inserir a taxa 
de interesse (representámos como uint32)
5 - Para definir os parâmetros iniciais da função 3, temos que selecionar o endereço correspondente ao Lessee e inserir a duração 
(em ciclos) (representámos como uint32)
6 - A partir daqui estamos no estado VALID. Podemos por exemplo chamar a função addTokens, em que passamos o endereço de uma entidade à qual 
queremos adicionar tokens. Estes tokens depois podem ser sempre consultados numa estrutura de dados pública "balances" que recebe o endereço 
da entidade que queremos consultar o saldo
7 - Supondo que cada ciclo tem uma duração de 3 minutos, então podemos fazer advanceCycle de 3 em 3 minutos e consultar o cycle correspondente 
com a função getCurrentCycle. De referir que começamos a contagem logo no ciclo 1 (e esta variável começa precisamente com esse valor)
8 - Assumindo que o lessee tem tokens na sua balance suficientes para pagar a renda, então podemos, por exemplo, chamar o payRental. Existe uma 
estrutura de dados pública chamada "paidRentals" que vai atribuir a renda de um determinado ciclo como paga ou não (true or false) e se for paga 
é incrementado o número de rendas e valores mensais pagos (este só pode ser menor à duração do contrato).
9 - Existem várias funções para consulta de estado de determinadas variáveis e os nomes das outras funções pertencentes ao contrato são 
autodescritivos, estando ainda especificados em comentários no próprio código


Gas costs: Para fazer deploy do smart contract, o gas limit minímo tem que ser 3276221 (para ser maior ou igual ao transaction cost), 
sendo o execution cost nesse caso 2487817, que corresponde ao custo das operações computacionais (e por isso depende da nossa implementação). 
