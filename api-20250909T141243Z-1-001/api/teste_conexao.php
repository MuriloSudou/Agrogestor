<?php
require 'conexao.php';
$con = conectar();
if ($con) {
    echo "Conexão OK!";
}
?>