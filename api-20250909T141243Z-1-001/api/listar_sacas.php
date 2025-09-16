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
    // A query junta as tabelas para buscar o nome do cultivo
    $sql = "SELECT 
                sc.id, 
                sc.cultivo_id, 
                sc.quantidade, 
                sc.peso_medio_kg,
                sc.data_colheita,
                c.cultura as nome_cultivo
            FROM 
                sacas_colhidas sc
            JOIN 
                cultivos c ON sc.cultivo_id = c.id
            WHERE 
                c.propriedade_id = ? 
            ORDER BY 
                sc.data_colheita DESC";
                
    $stmt = $conexao->prepare($sql);
    $stmt->bind_param("i", $propriedade_id);
    $stmt->execute();
    $resultado = $stmt->get_result();
    
    $sacas = [];
    while ($linha = $resultado->fetch_assoc()) {
        $sacas[] = $linha;
    }
    
    echo json_encode($sacas);

} catch (Exception $e) {
    echo json_encode([]);
} finally {
    if (isset($conexao)) {
        $stmt->close();
        $conexao->close();
    }
}
?>