<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
require 'conexao.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $propriedade_id = $_POST['propriedade_id'] ?? null;
    $data_evento = $_POST['data_evento'] ?? null;
    $titulo_evento = $_POST['titulo_evento'] ?? null;
    $descricao_evento = $_POST['descricao_evento'] ?? null;

    if ($propriedade_id === null || $data_evento === null || $titulo_evento === null) {
        exit(json_encode(["status" => "error", "message" => "Dados incompletos."]));
    }

    try {
        $conexao = conectar();
        $stmt = $conexao->prepare("INSERT INTO eventos_calendario (propriedade_id, data_evento, titulo_evento, descricao_evento) VALUES (?, ?, ?, ?)");
        $stmt->bind_param("isss", $propriedade_id, $data_evento, $titulo_evento, $descricao_evento);

        if ($stmt->execute()) {
            echo json_encode(["status" => "success", "message" => "Evento cadastrado com sucesso."]);
        } else {
            echo json_encode(["status" => "error", "message" => "Erro ao cadastrar evento."]);
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