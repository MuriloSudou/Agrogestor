<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");

require 'conexao.php';

$propriedade_id = $_GET['propriedade_id'] ?? null;

if ($propriedade_id === null) {
    exit(json_encode(['status' => 'error', 'message' => 'ID da propriedade não fornecido.']));
}

try {
    $conexao = conectar();
    $dados = [];

    // 1. Buscar nome da propriedade (já existia)
    $stmt = $conexao->prepare("SELECT nome_propriedade FROM propriedades WHERE id = ?");
    $stmt->bind_param("i", $propriedade_id);
    $stmt->execute();
    $resultado = $stmt->get_result();
    if ($resultado->num_rows > 0) {
        $dados['nome_propriedade'] = $resultado->fetch_assoc()['nome_propriedade'];
    }
    $stmt->close();

    // 2. Contar o número total de cultivos (já existia)
    $stmt = $conexao->prepare("SELECT COUNT(*) as total_cultivos FROM cultivos WHERE propriedade_id = ?");
    $stmt->bind_param("i", $propriedade_id);
    $stmt->execute();
    $resultado = $stmt->get_result();
    $dados['total_cultivos'] = $resultado->fetch_assoc()['total_cultivos'] ?? 0;
    $stmt->close();
    
    // 3. Somar o valor total das notas fiscais (já existia)
    $stmt = $conexao->prepare("SELECT SUM(valor) as custo_total FROM notas_fiscais WHERE propriedade_id = ?");
    $stmt->bind_param("i", $propriedade_id);
    $stmt->execute();
    $resultado = $stmt->get_result();
    $dados['custo_total'] = $resultado->fetch_assoc()['custo_total'] ?? 0.00;
    $stmt->close();

    // 4. NOVO: Buscar o resumo de sacas por cultivo
    $stmt = $conexao->prepare("
        SELECT 
            c.cultura as nome_cultivo,
            SUM(sc.quantidade) as total_sacas
        FROM 
            sacas_colhidas sc
        JOIN 
            cultivos c ON sc.cultivo_id = c.id
        WHERE 
            c.propriedade_id = ?
        GROUP BY 
            c.cultura
        ORDER BY 
            total_sacas DESC
    ");
    $stmt->bind_param("i", $propriedade_id);
    $stmt->execute();
    $resultado = $stmt->get_result();
    $resumo_sacas = [];
    while ($linha = $resultado->fetch_assoc()) {
        $resumo_sacas[] = $linha;
    }
    $dados['resumo_sacas'] = $resumo_sacas; // Adiciona a lista ao resultado final
    $stmt->close();


    echo json_encode(['status' => 'success', 'data' => $dados]);

} catch (Exception $e) {
    echo json_encode(['status' => 'error', 'message' => 'Erro no servidor: ' . $e->getMessage()]);
} finally {
    if (isset($conexao)) {
        $conexao->close();
    }
}
?>