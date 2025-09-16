<?php
// Define os cabeçalhos para permitir requisições de qualquer origem (CORS)
// e para que a resposta seja sempre em formato JSON.
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

// 1. DADOS DE CONEXÃO
$db_host = 'localhost';
$db_user = 'root';
$db_pass = 'root';
$db_name = 'agogestor_db';

// 2. FUNÇÃO PARA CONECTAR
function conectar() {
    // Usa as variáveis definidas acima para criar a conexão.
    global $db_host, $db_user, $db_pass, $db_name;
    
    $conexao = new mysqli($db_host, $db_user, $db_pass, $db_name);

    // 3. VERIFICAÇÃO DE ERRO
    // Se a conexão falhar, o script para e exibe o erro.
    if ($conexao->connect_error) {
        die("Erro de Conexão: " . $conexao->connect_error);
    }

    // Garante que a comunicação use o padrão UTF-8 (para acentos).
    $conexao->set_charset("utf8mb4");

    // Retorna o objeto de conexão para ser usado em outros scripts.
    return $conexao;
}
?>
