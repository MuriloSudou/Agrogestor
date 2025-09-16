<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");

require 'conexao.php';

header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    
    $email = isset($_POST['email']) ? $_POST['email'] : '';
    $senha = isset($_POST['senha']) ? $_POST['senha'] : '';

    if (empty($email) || empty($senha)) {
        echo json_encode(['status' => 'error', 'message' => 'Email e senha são obrigatórios.']);
        exit;
    }
    
    $conexao = conectar();
    $stmt = $conexao->prepare("SELECT id, nome, senha FROM agricultores WHERE email = ?");
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $resultado = $stmt->get_result();

    if ($resultado->num_rows === 1) {
        $agricultor = $resultado->fetch_assoc();

        if (password_verify($senha, $agricultor['senha'])) {
            // Senha correta
            echo json_encode([
                'status' => 'success',
                'message' => 'Login bem-sucedido!',
                'data' => [
                    'id' => $agricultor['id'],
                    'nome' => $agricultor['nome']
                ]
            ]);
        } else {
            // Senha incorreta
            echo json_encode(['status' => 'error', 'message' => 'Email ou senha inválidos.']);
        }
    } else {
        // Usuário não encontrado
        echo json_encode(['status' => 'error', 'message' => 'Email ou senha inválidos.']);
    }

    $stmt->close();
    $conexao->close();
}
?>