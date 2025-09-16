<?php
// CABEÇALHOS CORS COMPLETOS PARA PERMITIR LIGAÇÕES DA WEB
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// O browser envia um pedido 'OPTIONS' antes do 'POST' para verificar o CORS.
// Se for um, apenas confirmamos e saímos.
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit;
}

require 'conexao.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $propriedade_id = $_POST['propriedade_id'] ?? null;
    $cultivo_id = $_POST['cultivo_id'] ?? null;
    $numero_nota = $_POST['numero_nota'] ?? null;
    $valor = $_POST['valor'] ?? null;
    $data_emissao = $_POST['data_emissao'] ?? null;

    if ($propriedade_id === null || $cultivo_id === null || $numero_nota === null || $valor === null || $data_emissao === null) {
        exit(json_encode(["status" => "error", "message" => "Todos os campos são obrigatórios."]));
    }

    try {
        $conexao = conectar();
        $stmt = $conexao->prepare("INSERT INTO notas_fiscais (propriedade_id, cultivo_id, numero_nota, valor, data_emissao) VALUES (?, ?, ?, ?, ?)");
        $stmt->bind_param("iisds", $propriedade_id, $cultivo_id, $numero_nota, $valor, $data_emissao);

        if ($stmt->execute()) {
            echo json_encode(["status" => "success", "message" => "Nota fiscal cadastrada com sucesso."]);
        } else {
            echo json_encode(["status" => "error", "message" => "Erro ao cadastrar nota fiscal: " . $stmt->error]);
        }
    } catch (Exception $e) {
        echo json_encode(["status" => "error", "message" => "Erro no servidor."]);
    } finally {
        if (isset($conexao)) {
            $stmt->close();
            $conexao->close();
        }
    }
}
?>