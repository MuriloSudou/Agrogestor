<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
require 'conexao.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $id = $_POST['id'] ?? null;

    if ($id === null) {
        exit(json_encode(["status" => "error", "message" => "ID da nota fiscal não fornecido."]));
    }

    try {
        $conexao = conectar();
        $stmt = $conexao->prepare("DELETE FROM notas_fiscais WHERE id = ?");
        $stmt->bind_param("i", $id);

        if ($stmt->execute() && $stmt->affected_rows > 0) {
            echo json_encode(["status" => "success", "message" => "Nota fiscal excluída com sucesso."]);
        } else {
            echo json_encode(["status" => "error", "message" => "Erro ao excluir ou nota fiscal não encontrada."]);
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