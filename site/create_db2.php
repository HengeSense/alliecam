<?php
$db = array(
    'owner'=> 'blackwellfamily',
    'home' => 'http://blackwellfamily.s3-website-ap-southeast-2.amazonaws.com/',
    'albums' => array(),
    );
$prev_line = '';
$album = NULL;
$handle = @fopen("allfiles.txt", "r");
$valid_file_extensions = array('.jpg', 'jpeg', '.png', '.mov', 'mpeg', '.mpg', '.avi', '.m4a', '.wav');
$invalid_file_extensions = array('.psd');
if ($handle) {
    while (($buffer = fgets($handle, 4096)) !== false) {
        // if the line is an extension of the previous line, but doesn't
        // end in .jpg, .mov or .avi
        $buffer = trim(substr($buffer, 2));
        $len = strlen($buffer);
        $last_four_chars = strtolower(substr($buffer, $len - 4, 4));
        // echo $last_four_chars."\n";
        if (in_array($last_four_chars, $invalid_file_extensions) ||
            strtolower(substr($buffer, $len - 9, 9)) == 'thumbs.db' ||
            substr($buffer, $len - 9, 9) == '.DS_Store' ||
            substr($buffer, 0, 16) == 'iPod Photo Cache' ||
            substr($buffer, $len - 16, 16) == 'iPod Photo Cache') {
            // do nothing... 
        }
        else if (in_array($last_four_chars, $valid_file_extensions)) {
            // echo "found photo at $buffer\n";

            if ($album) {
                $album['photos'][] = array(
                    'uniqid' => uniqid(),
                    'caption' => '',
                    'url' => $buffer,
                );
            }
            else {
                echo "Error: photo with no album set at $buffer\n";
            }
        }
        else if ($prev_line != '' &&
                 substr($buffer, 0, strlen($prev_line)) == $prev_line) {
            if ($album) {
                // may be in a subdirectory
                $album['dateCreated'] = date('Y-m-d H:i:s', strtotime('20'.substr($buffer, 0, 5).'-01'));
                $album['name'] = substr($buffer, 6);
            }
            else {
                echo "ignoring line $buffer";
            }
        }
        else {
            // echo  "found new album $buffer\n";
            // store the prev album
            if ($album != NULL && count($album['photos'] > 0))
                $db['albums'][] = $album;
            $album = array(
                'uniqid' => uniqid(),
                'dateCreated' => date('Y-mvi'-d H:i:s', strtotime('20'.substr($buffer, 0, 5).'-01')),
                'name' => substr($buffer, 6),
                'photos' => array(),
            );
        }
        $prev_line = $buffer;
    }
    if (!feof($handle)) {
        echo "Error: unexpected fgets() fail\n";
    }
    fclose($handle);

    // var_dump($db);
    $db_json = json_encode($db);
    echo $db_json;
}
?>
