<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
require 'conexao.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Nomes de campos corrigidos para corresponder ao que o Flutter envia
    $id_agricultor = $_POST['agricultor_id'] ?? '';
    $nome_propriedade = $_POST['nome'] ?? '';
    $area_ha = $_POST['area_ha'] ?? '';
    $matricula = $_POST['matricula'] ?? ''; // Opcional
    $endereco = $_POST['endereco'] ?? '';   // Opcional

    if (empty($id_agricultor) || empty($nome_propriedade) || empty($area_ha)) {
        exit(json_encode(['status' => 'error', 'message' => 'Nome da propriedade e área são obrigatórios.']));
    }

    try {
        $conexao = conectar();
        // CORRIGIDO: nome da coluna é nome_propriedade
        $stmt = $conexao->prepare("INSERT INTO propriedades (id_agricultor, nome_propriedade, area_ha, matricula, endereco) VALUES (?, ?, ?, ?, ?)");
        $stmt->bind_param("isdss", $id_agricultor, $nome_propriedade, $area_ha, $matricula, $endereco);

        if ($stmt->execute()) {
            echo json_encode(['status' => 'success', 'message' => 'Propriedade cadastrada com sucesso!']);
        } else {
            echo json_encode(['status' => 'error', 'message' => 'Erro ao cadastrar propriedade: ' . $stmt->error]);
        }
    } catch (Exception $e) {
        echo json_encode(['status' => 'error', 'message' => 'Erro no servidor.']);
    } finally {
        if (isset($conexao)) {
            $stmt->close();
            $conexao->close();
        }
    }
}
?>