<?php

$db = array();

if ($root_handle = opendir('static/data')) {
    while (false !== ($owner = readdir($root_handle))) {
        if (substr($owner, 0, 1) != '.') {
            // echo "$owner\n";
            $db['owner'] = $owner;
            $db['home'] = $owner;
            $db_albums = array();
            if ($owner_handle = opendir("static/data/$owner")) {
                while (false !== ($album = readdir($owner_handle))) {
                    if (substr($album, 0, 1) != '.') {
                        // echo "--$album\n";
                        $db_album = array(
                            'uniqid' => uniqid(),
                            'dateCreated' => date('Y-m-d'),
                            'path' => $album,
                            'name' => $album,
                        );
                        if ($album_handle = opendir("static/data/$owner/$album")) {
                            $db_photos = array();
                            while (false !== ($image = readdir($album_handle))) {
                                if (substr($image, 0, 1) != '.') {
                                    // echo "----$image\n";
                                    $db_photo = array(
                                        'uniqid' => uniqid(),
                                        'caption' => '',
                                        'filename' => $image,
                                    );
                                    $db_photos[] = $db_photo;
                                }
                            }
                            closedir($album_handle);
                            $db_album['photos'] = $db_photos;
                        }
                        $db_albums[] = $db_album;
                    }
                }
                closedir($owner_handle);
            }
            $db['albums'] = $db_albums;
        }
    }
    closedir($root_handle);
}

echo json_encode($db);

?>
