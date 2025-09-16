<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");

require 'conexao.php';

header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    
    $nome = isset($_POST['nome']) ? $_POST['nome'] : '';
    $email = isset($_POST['email']) ? $_POST['email'] : '';
    $senha_plana = isset($_POST['senha']) ? $_POST['senha'] : '';

    if (empty($nome) || empty($email) || empty($senha_plana)) {
        echo json_encode(['status' => 'error', 'message' => 'Todos os campos são obrigatórios.']);
        exit;
    }

    if (strlen($senha_plana) < 6) {
        echo json_encode(['status' => 'error', 'message' => 'A senha deve ter no mínimo 6 caracteres.']);
        exit;
    }

    $senha_hash = password_hash($senha_plana, PASSWORD_DEFAULT);
    $conexao = conectar();

    $stmt = $conexao->prepare("INSERT INTO agricultores (nome, email, senha) VALUES (?, ?, ?)");
    $stmt->bind_param("sss", $nome, $email, $senha_hash);

    if ($stmt->execute()) {
        $novoId = $conexao->insert_id;
        echo json_encode([
            'status' => 'success', 
            'message' => 'Cadastro realizado com sucesso!',
            'id' => $novoId
        ]);
    } else {
        if ($conexao->errno === 1062) {
             echo json_encode(['status' => 'error', 'message' => 'Este email já está em uso.']);
        } else {
             echo json_encode(['status' => 'error', 'message' => 'Erro ao cadastrar: ' . $stmt->error]);
        }
    }

    $stmt->close();
    $conexao->close();
}
?>