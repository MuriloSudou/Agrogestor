<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
require 'conexao.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $id = $_POST['id'] ?? null;
    $cultivo_id = $_POST['cultivo_id'] ?? null;
    $numero_nota = $_POST['numero_nota'] ?? null;
    $valor = $_POST['valor'] ?? null;
    $data_emissao = $_POST['data_emissao'] ?? null;

    if ($id === null || $cultivo_id === null || $numero_nota === null || $valor === null || $data_emissao === null) {
        exit(json_encode(["status" => "error", "message" => "Todos os campos são obrigatórios."]));
    }
    
    try {
        $conexao = conectar();
        $stmt = $conexao->prepare("UPDATE notas_fiscais SET cultivo_id = ?, numero_nota = ?, valor = ?, data_emissao = ? WHERE id = ?");
        $stmt->bind_param("isdsi", $cultivo_id, $numero_nota, $valor, $data_emissao, $id);

        if ($stmt->execute()) {
            if ($stmt->affected_rows > 0) {
                echo json_encode(["status" => "success", "message" => "Nota fiscal atualizada com sucesso."]);
            } else {
                echo json_encode(["status" => "info", "message" => "Nenhuma alteração foi feita."]);
            }
        } else {
            echo json_encode(["status" => "error", "message" => "Erro ao atualizar nota fiscal: " . $stmt->error]);
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