<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
require 'conexao.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $id = $_POST['id'] ?? null;

    if ($id === null) {
        exit(json_encode(["status" => "error", "message" => "ID do evento não fornecido."]));
    }

    try {
        $conexao = conectar();
        $stmt = $conexao->prepare("DELETE FROM eventos_calendario WHERE id = ?");
        $stmt->bind_param("i", $id);

        if ($stmt->execute() && $stmt->affected_rows > 0) {
            echo json_encode(["status" => "success", "message" => "Evento excluído com sucesso."]);
        } else {
            echo json_encode(["status" => "error", "message" => "Erro ao excluir ou evento não encontrado."]);
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