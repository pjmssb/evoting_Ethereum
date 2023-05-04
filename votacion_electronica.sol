// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract Evoting {
    //Estructuras necesarias para el funcionamiento del sistema
    //Estructura para los votantes: el id sera el identificador unico que nos ayuda a validar que no repita el voto en este caso sera el correo electronico
    struct Votante {
        string id;
        address direccion;
        bool estadoVoto;
    }
    //Estructura para los candidatos
    struct Candidato {
        string id;
        string nombre;
        uint256 votosAFavor;
    }
    //Estructura para las dignidades
    struct Dignidad {
        string id;
        string nombre;
        uint256 cantidadCandidatos;
        uint256 votosNulos;
        uint256 votosBlancos;
        mapping(uint256 => Candidato) candidatos;
        // Candidato [] candidatos;
    }
    uint256 numDignidades;
    address public cuentaContrato;
    address[] public cuentasAdministradoras;
    Votante[] private votantesRegistrados;
    string[] private idsValidos;
    string[][] private informacionHabilitante;
    // Dignidad [] public dignidades;
    mapping(uint256 => Dignidad) public dignidades;

    //Funcion para registrar un administrador del sistema, el requiere hace que solo la persona que despleglo el contrato tenga acceso a agregar administradores
    function agregarAdministrador(address _direccion) public {
        require(msg.sender == cuentasAdministradoras[0]);
        cuentasAdministradoras.push(_direccion);
    }

    //Funcion para obtener las cuentas administradoras
    function obtenerCuentasAdministradoras()
        public
        view
        returns (string[] memory)
    {
        string[] memory cuentasAdministradorasAEnviar = new string[](
            cuentasAdministradoras.length
        );
        for (uint256 i = 0; i < cuentasAdministradoras.length; i++) {
            cuentasAdministradorasAEnviar[i] = toString(cuentasAdministradoras[i]);

        }

        return cuentasAdministradorasAEnviar;
    }

    constructor(string[] memory _idValidos) {
        cuentasAdministradoras.push(msg.sender);
        cuentaContrato = msg.sender;
        idsValidos = _idValidos;
    }

    function uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + (j % 10)));
            j /= 10;
        }
        str = string(bstr);
    }

    //Funcion que convierte una direccion de ethereum a string
    function toString(address account) public pure returns (string memory) {
        return toString(abi.encodePacked(account));
    }

    function toString(uint256 value) public pure returns (string memory) {
        return toString(abi.encodePacked(value));
    }

    function toString(bytes32 value) public pure returns (string memory) {
        return toString(abi.encodePacked(value));
    }

    function toString(bytes memory data) public pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    //Funcion para obtener los id validos
    function obtenerIdsValidos() public view returns (string[] memory) {
        return idsValidos;
    }

    //Funcion para validar si una cuenta es administradora
    function esCuentaAdministradora(
        address _direccion
    ) private view returns (bool) {
        for (uint256 i = 0; i < cuentasAdministradoras.length; i++) {
            if (cuentasAdministradoras[i] == _direccion) {
                return true;
            }
        }
        return false;
    }

    //Funcion para comprobar si un usuario es cuenta administradora
    function soyAdministrador() public view returns (bool) {
        return esCuentaAdministradora(msg.sender);
    }

    //Funcion que verifica si la persona que esta ejecutando una accion esta registrda
    function estoyRegistrado() public view returns (bool) {
        for (uint256 i = 0; i < votantesRegistrados.length; i++) {
            if (
                keccak256(abi.encodePacked(votantesRegistrados[i].direccion)) ==
                keccak256(abi.encodePacked(msg.sender))
            ) {
                return true;
            }
        }
        return false;
    }

    //Funcion para validar si un votante ya esta registrado
    function esVotanteRegistrado(
        address _direccion
    ) private view returns (bool) {
        for (uint256 i = 0; i < votantesRegistrados.length; i++) {
            if (
                keccak256(abi.encodePacked(votantesRegistrados[i].direccion)) ==
                keccak256(abi.encodePacked(_direccion))
            ) {
                return true;
            }
        }
        return false;
    }

    //Funcion para verificar si el votante ya voto o no
    function yaVoto() public view returns (bool) {
        for (uint256 i = 0; i < votantesRegistrados.length; i++) {
            if (
                keccak256(abi.encodePacked(votantesRegistrados[i].direccion)) ==
                keccak256(abi.encodePacked(msg.sender))
            ) {
                return votantesRegistrados[i].estadoVoto;
            }
        }
        return false;
    }

    //Funcion para validar si un id ya existe
    function idYaExiste(string memory _id) private view returns (bool) {
        for (uint256 i = 0; i < votantesRegistrados.length; i++) {
            if (
                keccak256(abi.encodePacked(votantesRegistrados[i].id)) ==
                keccak256(abi.encodePacked(_id))
            ) {
                return true;
            }
        }
        return false;
    }

    //Funcion que verifica si el id es valido
    function esIdValido(string memory _id) private view returns (bool) {
        for (uint256 i = 0; i < idsValidos.length; i++) {
            if (
                keccak256(abi.encodePacked(idsValidos[i])) ==
                keccak256(abi.encodePacked(_id))
            ) {
                return true;
            }
        }
        return false;
    }

    //Funcion para validar si una dignidad ya esta registrada
    function esDignidadRegistrada(
        string memory _id
    ) private view returns (bool) {
        for (uint256 i = 0; i < numDignidades; i++) {
            if (
                keccak256(abi.encodePacked(dignidades[i].id)) ==
                keccak256(abi.encodePacked(_id))
            ) {
                return true;
            }
        }
        return false;
    }

    //Funcion para validar si los candidatos ya estan registrados
    function sonCandidatosRegistrados(
        string[][] memory _candidatos
    ) private view returns (bool) {
        for (uint256 i = 0; i < _candidatos.length; i++) {
            for (uint256 j = 0; j < numDignidades; j++) {
                for (uint256 k = 0; k < dignidades[j].cantidadCandidatos; k++) {
                    if (
                        keccak256(
                            abi.encodePacked(dignidades[j].candidatos[k].id)
                        ) == keccak256(abi.encodePacked(_candidatos[i][0]))
                    ) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    //Funcion que verifica que la cantidad de candidatos enviados sea correcta segun la dignidad elegida
    function cantidadCandidatosCorrecta(
        uint256 _cantidadCandidatos,
        string memory _idDignidad
    ) private view returns (bool) {
        for (uint256 i = 0; i < numDignidades; i++) {
            if (
                keccak256(abi.encodePacked(dignidades[i].id)) ==
                keccak256(abi.encodePacked(_idDignidad))
            ) {
                if (dignidades[i].cantidadCandidatos == _cantidadCandidatos) {
                    return true;
                }
            }
        }
        return false;
    }

    //Funcion para registrar un votante, el sistema solamente podra hacerlo
    function registrarseParaVotar(string memory _id) public {
        require(esIdValido(_id), "La persona no tiene permiso de registrarse");
        require(!idYaExiste(_id), "El votante ya esta registrado");
        Votante memory votante = Votante(_id, msg.sender, false);
        votantesRegistrados.push(votante);
    }

    //Funcion para registrar una dignidad
    function registrarDignidad(
        string memory _id,
        string memory _nombre,
        uint256 _cantidadCandidatos
    ) public {
        require(
            esCuentaAdministradora(msg.sender),
            "No tiene permisos para realizar esta accion"
        );
        require(!esDignidadRegistrada(_id), "La dignidad ya esta registrada");
        Dignidad storage dignidad = dignidades[numDignidades++];
        dignidad.id = _id;
        dignidad.nombre = _nombre;
        dignidad.cantidadCandidatos = _cantidadCandidatos;
    }

    //Funcion para registrar un candidato
    function registrarCandidatos(
        string[][] memory _candidatos,
        string memory _idDignidad
    ) public {
        require(
            esCuentaAdministradora(msg.sender),
            "No tiene permisos para realizar esta accion"
        );
        require(
            !sonCandidatosRegistrados(_candidatos),
            "El candidato ya esta registrado"
        );
        require(
            cantidadCandidatosCorrecta(_candidatos.length, _idDignidad),
            "La cantidad de candidatos no es la correcta"
        );
        for (uint256 i = 0; i < numDignidades; i++) {
            if (
                keccak256(abi.encodePacked(dignidades[i].id)) ==
                keccak256(abi.encodePacked(_idDignidad))
            ) {
                for (uint256 j = 0; j < dignidades[i].cantidadCandidatos; j++) {
                    dignidades[i].candidatos[j] = Candidato(
                        _candidatos[j][0],
                        _candidatos[j][1],
                        0
                    );
                }
            }
        }
    }

    //Funcion para obtener las dignidades registradas
    function obtenerDignidades() public view returns (string[][] memory) {
        string[][] memory dignidadesRegistradas = new string[][](numDignidades);
        for (uint256 i = 0; i < numDignidades; i++) {
            dignidadesRegistradas[i] = new string[](5);
            dignidadesRegistradas[i][0] = dignidades[i].id;
            dignidadesRegistradas[i][1] = dignidades[i].nombre;
            dignidadesRegistradas[i][2] = uint2str(
                dignidades[i].cantidadCandidatos
            );
            dignidadesRegistradas[i][3] = uint2str(dignidades[i].votosBlancos);
            dignidadesRegistradas[i][4] = uint2str(dignidades[i].votosNulos);
        }
        return dignidadesRegistradas;
    }

    //Funcion para obtener los candidatos de una dignidad
    function obtenerCandidatos(
        string memory _idDignidad
    ) public view returns (Candidato[] memory) {
        Candidato[] memory candidatos;
        for (uint256 i = 0; i < numDignidades; i++) {
            if (
                keccak256(abi.encodePacked(dignidades[i].id)) ==
                keccak256(abi.encodePacked(_idDignidad))
            ) {
                candidatos = new Candidato[](dignidades[i].cantidadCandidatos);
                for (uint256 j = 0; j < dignidades[i].cantidadCandidatos; j++) {
                    candidatos[j] = dignidades[i].candidatos[j];
                }
            }
        }
        return candidatos;
    }

    //Funcion para votar por todas las dignidades y sus candidatos
    function votar(string[] memory _candidatos) public {
        require(
            esVotanteRegistrado(msg.sender),
            "El votante no esta registrado"
        );
        for (uint i = 0; i < votantesRegistrados.length; i++) {
            if (
                keccak256(abi.encodePacked(votantesRegistrados[i].direccion)) ==
                keccak256(abi.encodePacked(msg.sender))
            ) {
                require(!yaVoto(), "El votante ya voto");
                votantesRegistrados[i].estadoVoto = true;
            }
        }
        for (uint i = 0; i < _candidatos.length; i++) {
            for (uint j = 0; j < numDignidades; j++) {
                for (uint k = 0; k < dignidades[j].cantidadCandidatos; k++) {
                    if (
                        keccak256(
                            abi.encodePacked(dignidades[j].candidatos[k].id)
                        ) == keccak256(abi.encodePacked(_candidatos[i]))
                    ) {
                        dignidades[j].candidatos[k].votosAFavor++;
                    }
                }
            }
        }
    }

    //Funcion para obtener a los gandores de cada dignidad
    function obtenerGanadores() public view returns (string[][] memory) {
        string[][] memory ganadores = new string[][](numDignidades);
        for (uint i = 0; i < numDignidades; i++) {
            uint256 mayor = 0;
            ganadores[i] = new string[](4);
            ganadores[i][0] = dignidades[i].id;
            ganadores[i][1] = dignidades[i].nombre;
            for (uint j = 0; j < dignidades[i].cantidadCandidatos; j++) {
                if (dignidades[i].candidatos[j].votosAFavor > mayor) {
                    mayor = dignidades[i].candidatos[j].votosAFavor;
                    ganadores[i][2] = dignidades[i].candidatos[j].id;
                    ganadores[i][3] = dignidades[i].candidatos[j].nombre;
                }
            }
        }
        return ganadores;
    }

    //Obtener los ganadores y en caso de empate devolver todos los candidatos con el mismo numero de votos
    function obtenerGanadoresEmpate() public view returns (string[][] memory) {
        string[][] memory ganadores = new string[][](numDignidades);
        for (uint i = 0; i < numDignidades; i++) {
            uint256 mayor = 0;
            ganadores[i] = new string[](5);
            ganadores[i][0] = dignidades[i].id;
            ganadores[i][1] = dignidades[i].nombre;
            for (uint j = 0; j < dignidades[i].cantidadCandidatos; j++) {
                if (dignidades[i].candidatos[j].votosAFavor > mayor) {
                    mayor = dignidades[i].candidatos[j].votosAFavor;
                }
            }
            for (uint j = 0; j < dignidades[i].cantidadCandidatos; j++) {
                if (dignidades[i].candidatos[j].votosAFavor == mayor) {
                    ganadores[i][2] = string(
                        bytes.concat(
                            bytes(ganadores[i][2]),
                            bytes(dignidades[i].candidatos[j].id)
                        )
                    );
                    ganadores[i][3] = string(
                        bytes.concat(
                            bytes(ganadores[i][3]),
                            bytes(dignidades[i].candidatos[j].nombre)
                        )
                    );
                    ganadores[i][4] = string(
                        bytes.concat(
                            bytes(ganadores[i][4]),
                            bytes(uint2str(mayor))
                        )
                    );
                    if (j != dignidades[i].cantidadCandidatos - 1) {
                        ganadores[i][2] = string(
                            bytes.concat(bytes(ganadores[i][2]), ",")
                        );
                        ganadores[i][3] = string(
                            bytes.concat(bytes(ganadores[i][3]), ",")
                        );
                        ganadores[i][4] = string(
                            bytes.concat(bytes(ganadores[i][4]), ",")
                        );
                    }
                }
            }
        }
        return ganadores;
    }

    //Funcion que devuelve la cantidad de votantes registrados y la cantidad que ya votaron
    function obtenerVotantes() public view returns (uint256, uint256) {
        uint256 votantes = 0;
        uint256 votaron = 0;
        for (uint i = 0; i < votantesRegistrados.length; i++) {
            votantes++;
            if (votantesRegistrados[i].estadoVoto) {
                votaron++;
            }
        }
        return (votantes, votaron);
    }
    //VALIDAR EN CASO DE EMPATE

    //DATOS PRUEBA
    //"medPosPres","Presidentes Medicina",3
    //"comPosPres","Presidentes Computacion",1
    //[["0105599971","Juan Perez"],["0105599972","Martha Urgile"],["0105599973","Jhon Doe"]],"medPosPres"
    //[["0105599974","Pedro Flores"]],"comPosPres"
    //"123456789"
    //["0105599971","0105599974"]
}
