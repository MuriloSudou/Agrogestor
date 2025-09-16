<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
require 'conexao.php';

$propriedade_id = $_GET['propriedade_id'] ?? null;

if ($propriedade_id === null) {
    exit(json_encode([]));
}

try {
    $conexao = conectar();
    $stmt = $conexao->prepare("SELECT id, data_evento, titulo_evento, descricao_evento FROM eventos_calendario WHERE propriedade_id = ? ORDER BY data_evento ASC");
    $stmt->bind_param("i", $propriedade_id);
    $stmt->execute();
    $resultado = $stmt->get_result();
    
    $eventos = [];
    while ($linha = $resultado->fetch_assoc()) {
        $eventos[] = $linha;
    }
    
    echo json_encode($eventos);

} catch (Exception $e) {
    echo json_encode([]);
} finally {
    if (isset($conexao)) {
        $stmt->close();
        $conexao->close();
    }
}
?>