<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
require 'conexao.php';

// CORRIGIDO: Usa GET para buscar dados, que é o padrão para listagens
$agricultor_id = $_GET['agricultor_id'] ?? null;

if ($agricultor_id === null) {
    exit(json_encode([])); // Retorna lista vazia se o ID não for fornecido
}

try {
    $conexao = conectar();
    $stmt = $conexao->prepare("SELECT id, nome_propriedade, area_ha FROM propriedades WHERE id_agricultor = ?");
    $stmt->bind_param("i", $agricultor_id);
    $stmt->execute();
    $resultado = $stmt->get_result();
    
    $propriedades = [];
    while ($linha = $resultado->fetch_assoc()) {
        $propriedades[] = $linha;
    }
    
    // Retorna a lista em formato JSON, mesmo que esteja vazia []
    echo json_encode($propriedades);

} catch (Exception $e) {
    echo json_encode([]); // Retorna lista vazia em caso de erro
} finally {
    if (isset($conexao)) {
        $stmt->close();
        $conexao->close();
    }
}
?>