<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
require 'conexao.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $id = $_POST['id'] ?? null;
    // CORRIGIDO: Nomes de campos consistentes
    $cultura = $_POST['cultura'] ?? null;
    $area = $_POST['area'] ?? null;
    $inicio = $_POST['inicio'] ?? null;

    if ($id === null || $cultura === null || $area === null || $inicio === null) {
        exit(json_encode(["status" => "error", "message" => "Dados incompletos."]));
    }

    try {
        $conexao = conectar();
        // CORRIGIDO: Query e bind_param corretos
        $stmt = $conexao->prepare("UPDATE cultivos SET cultura = ?, area = ?, inicio = ? WHERE id = ?");
        $stmt->bind_param("sdsi", $cultura, $area, $inicio, $id);

        if ($stmt->execute()) {
            if ($stmt->affected_rows > 0) {
                echo json_encode(["status" => "success", "message" => "Cultivo atualizado com sucesso."]);
            } else {
                echo json_encode(["status" => "info", "message" => "Nenhuma alteração foi feita."]);
            }
        } else {
            echo json_encode(["status" => "error", "message" => "Erro ao atualizar cultivo: " . $stmt->error]);
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