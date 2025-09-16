<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
require 'conexao.php';

// CORRIGIDO: Usa GET, que é o padrão para listagens
$propriedade_id = $_GET['propriedade_id'] ?? null;

if ($propriedade_id === null) {
    exit(json_encode([])); // Retorna lista vazia se não houver ID
}

try {
    $conexao = conectar();
    $stmt = $conexao->prepare("SELECT id, cultura, area, inicio FROM cultivos WHERE propriedade_id = ?");
    $stmt->bind_param("i", $propriedade_id);
    $stmt->execute();
    $resultado = $stmt->get_result();
    
    $cultivos = [];
    while ($linha = $resultado->fetch_assoc()) {
        $cultivos[] = $linha;
    }
    
    echo json_encode($cultivos);

} catch (Exception $e) {
    echo json_encode([]);
} finally {
    if (isset($conexao)) {
        $stmt->close();
        $conexao->close();
    }
}
?>