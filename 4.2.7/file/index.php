<?php
  if (isset($_GET['mimetype']) && isset($_GET['filetype']) && isset($_GET['filename'])) {
    $fname = '../_Up_l04d/'.basename($_GET['filename']);
    $mimetype = $_GET['mimetype'];
    if (file_exists($fname)) {
      header("Content-type: ".$mimetype);
      @readfile($fname);
    }
    else {
      header("Content-type: image/jpeg");
      @readfile('missing.jpg');
    }
  }
  else {
    header("Content-type: image/jpeg");
    @readfile('unauthorized.jpg');
  }
?>
