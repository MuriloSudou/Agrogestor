<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
require 'conexao.php';

// CORRIGIDO: Usa GET para listagens
$propriedade_id = $_GET['propriedade_id'] ?? null;

if ($propriedade_id === null) {
    exit(json_encode([])); 
}

try {
    $conexao = conectar();
    // MELHORADO: A query agora junta as tabelas para buscar o nome do cultivo
    $sql = "SELECT 
                nf.id, 
                nf.numero_nota, 
                nf.valor, 
                nf.data_emissao, 
                nf.cultivo_id,
                c.cultura as nome_cultivo
            FROM 
                notas_fiscais nf
            LEFT JOIN 
                cultivos c ON nf.cultivo_id = c.id
            WHERE 
                nf.propriedade_id = ?";
                
    $stmt = $conexao->prepare($sql);
    $stmt->bind_param("i", $propriedade_id);
    $stmt->execute();
    $resultado = $stmt->get_result();
    
    $notas = [];
    while ($linha = $resultado->fetch_assoc()) {
        $notas[] = $linha;
    }
    
    echo json_encode($notas);

} catch (Exception $e) {
    echo json_encode([]);
} finally {
    if (isset($conexao)) {
        $stmt->close();
        $conexao->close();
    }
}
?>