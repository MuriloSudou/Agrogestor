<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
require 'conexao.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $cultivo_id = $_POST['cultivo_id'] ?? null;
    $quantidade = $_POST['quantidade'] ?? null;
    $peso_medio_kg = $_POST['peso_medio_kg'] ?? null;
    $data_colheita = $_POST['data_colheita'] ?? null;

    if ($cultivo_id === null || $quantidade === null || $peso_medio_kg === null || $data_colheita === null) {
        exit(json_encode(["status" => "error", "message" => "Todos os campos são obrigatórios."]));
    }

    try {
        $conexao = conectar();
        $stmt = $conexao->prepare("INSERT INTO sacas_colhidas (cultivo_id, quantidade, peso_medio_kg, data_colheita) VALUES (?, ?, ?, ?)");
        $stmt->bind_param("iids", $cultivo_id, $quantidade, $peso_medio_kg, $data_colheita);

        if ($stmt->execute()) {
            echo json_encode(["status" => "success", "message" => "Registo de colheita salvo com sucesso."]);
        } else {
            echo json_encode(["status" => "error", "message" => "Erro ao salvar registo."]);
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