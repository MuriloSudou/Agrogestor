<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
require 'conexao.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $propriedade_id = $_POST['propriedade_id'] ?? null;
    $cultura = $_POST['cultura'] ?? null;
    $area = $_POST['area'] ?? null;
    $inicio = $_POST['inicio'] ?? null;

    if ($propriedade_id === null || $cultura === null || $area === null || $inicio === null) {
        exit(json_encode(["status" => "error", "message" => "Dados incompletos."]));
    }

    try {
        $conexao = conectar();
        $stmt = $conexao->prepare("INSERT INTO cultivos (propriedade_id, cultura, area, inicio) VALUES (?, ?, ?, ?)");
        $stmt->bind_param("isds", $propriedade_id, $cultura, $area, $inicio);

        if ($stmt->execute()) {
            echo json_encode(["status" => "success", "message" => "Cultivo cadastrado com sucesso."]);
        } else {
            echo json_encode(["status" => "error", "message" => "Erro ao cadastrar cultivo: " . $stmt->error]);
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