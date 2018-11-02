pragma solidity ^0.4;

contract GerenciaApolices{
    Dados[] public dadosApolices;
    address[] public apolices;
    uint public qtdApolices;
    mapping(uint => address) public apolicesEnd;
    mapping(string => uint) parametros;
    mapping(string => uint) diasSeca;

    struct Dados {
        address end;
        uint numero;
        string id;
        string estado;
        uint data;
    }

    function criarApolice(string _nome, string _id, string _ramo, string _estado, string _municipio, uint _parametro,
            uint _area, uint _custoHect, uint _premio) public {
        uint num = geraNumApolice(111111111111111, 999999999999999);

        address novaApolice = new Apolice(num, _nome, _id, _ramo , _estado, _municipio, _parametro, _area, _custoHect, _premio);
        Dados memory info = Dados(novaApolice, num, _id, _estado, now);
        dadosApolices.push(info);
        apolices.push(novaApolice);
        apolicesEnd[num] = novaApolice;
        qtdApolices += 1;
    }

    function geraNumApolice(uint min, uint max) public view returns (uint){
        return uint(sha3(qtdApolices + 1))%(min+max)-min;
    }

    function atualizaParametro(string municipio, uint valorAtualParametro, uint _diasSeca) public {
        parametros[municipio] = valorAtualParametro;
        diasSeca[municipio] = _diasSeca;
    }

    function obtemDadosParametro(string municipio) public view returns (uint, uint){
        return (parametros[municipio], diasSeca[municipio]);
    }

    function obtemApolices() public view returns(address[]) {
        return apolices;
    }

}

contract Apolice{
    uint numero;
    string nome;
    string id;    // CPF ou CNPJ
    string ramo;
    string estado;
    string municipio;
    uint parametro;
    uint area;           // Em hectares
    uint custoHect;      // Custo por hectare
    uint dataProposta;   // Data da criação
    uint dataIniVigencia;
    uint dataFimVigencia;
    uint premio;
    uint indenizacao;
    bool public liquidado;
    bool public ocorreuSinistro;
    bool public emDia;
    bool public contratada;


    constructor(uint _num, string _nome, string _id, string _ramo, string _estado, string _municipio,
                uint _parametro, uint _area, uint _custoHect, uint _premio) public {
        numero = _num;
        nome = _nome;
        id = _id;
        ramo = _ramo;
        estado = _estado;
        municipio = _municipio;
        parametro = _parametro;
        area = _area;
        custoHect = _custoHect;
        dataProposta = now;
        premio = _premio;
    }

    event NotificaSeguradoraSinistro(uint numeroApolice);

    function obtemDados() public view returns(uint, string, string, string, string,
                                    string, uint, uint, uint, uint ){
            return (numero, id, nome, ramo, estado, municipio, parametro, area, custoHect, premio);
    }

    function obtemDatas() public view returns (uint, uint, uint){
        return (dataProposta, dataIniVigencia, dataFimVigencia);
    }

    function aceitaProposta() public {
        dataIniVigencia = now;
        dataFimVigencia = dataIniVigencia + 356 days;
        emDia = true;
        contratada = true;

    }

    function atualizaStatusPagamento() public {
        emDia = !emDia;
    }

    function atualizaStatusLiquidado() public {
        require(!liquidado, "Essa apólice já foi liquidada!");
        liquidado = true;
    }

     function atualizaIndenizacao(uint valor) public {
         indenizacao = valor;
    }

    function atualizaDados(string _ramo, string _estado, string _municipio, uint _parametro, uint _area,
                            uint _custoHect, uint _premio) public {

         if(keccak256(abi.encodePacked(ramo)) != keccak256(abi.encodePacked(_ramo))){
             ramo = _ramo;
         }
         if(keccak256(abi.encodePacked(estado)) != keccak256(abi.encodePacked(_estado))){
             estado = _estado;
         }
         if(keccak256(abi.encodePacked(municipio)) != keccak256(abi.encodePacked(_municipio))){
             municipio = _municipio;
         }
         if(parametro != _parametro){
             parametro = _parametro;
         }
         if(area != _area){
             area = _area;
         }
         if(custoHect != _custoHect){
             custoHect = _custoHect;
         }
         if(premio != _premio){
             premio = _premio;
         }
    }

    function verificaEstaDentroVigencia() public view returns(bool) {
        return (dataFimVigencia >= now);
    }

    function verificaSinistro(uint valorAtualParametro, uint diasSeca) public {
        require(dataFimVigencia >= now, "Não está dentro da vigência!");
        require(emDia, "O pagamento não está em dia");
        require(!liquidado, "Essa apólice já foi liquidada!");
        if(diasSeca > 60 && valorAtualParametro < parametro){
            ocorreuSinistro = true;
            emit NotificaSeguradoraSinistro(numero);
        }
    }

}
