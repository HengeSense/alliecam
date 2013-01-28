<?php
require 'AWSSDKforPHP/aws.phar';
use Aws\Common\Aws;
use Aws\S3\Enum\CannedAcl;
use Guzzle\Http\EntityBody;

require_once 'phpSmug.php';

$smug = new phpSmug("APIKey=Sm9RMHcRr1yRg5KBTf8w2wolJEBHTJDC", "APIVer=1.2.2");
$login = $smug->login("EmailAddress=mblackwell8@gmail.com", "Password=alliecat8");
// var_dump($login);

// foreach ($smug->albums_get() as $album) {
//     // var_dump($album);
//     echo 'deleting album called: '.$album['Title'].PHP_EOL;
//     $smug->albums_delete("AlbumID=".$album['id']);
// }
// exit(0);

$smugmug_albums = array();
foreach ($smug->albums_get() as $album) {
    $smugmug_albums[$album['Title']] = $album;
}

// exit(0);

// Instantiate an S3 client
$s3 = Aws::factory('application/config/aws_config.php')->get('s3');
$bucket = 'blackwellfamily';
$tmp_filepath = 'tmp/';
$s3_fileroot = 'http://s3-ap-southeast-2.amazonaws.com/';
$s3_public_root = 'http://blackwellfamily.s3-website-ap-southeast-2.amazonaws.com/';

$i = 0;
$this_album_name = $last_album_name = '';
$album = NULL;
$objects_done_already = file_exists($tmp_filepath.'smugmug_objects_done.txt') ? explode(PHP_EOL, file_get_contents($tmp_filepath.'smugmug_objects_done.txt')) : array();

foreach ($s3->getIterator('ListObjects', array('Bucket' => $bucket)) as $object) {
    echo $bucket . '/' . $object['Key'].': ';
    $awspath_pre_extension = strstr($object['Key'], '.', TRUE);
    if (substr_compare($awspath_pre_extension, '_ac', -3, 3) === 0 ||
            substr_compare($awspath_pre_extension, '_thumb', -6, 6) === 0) {
        echo 'ignoring existing thumb or ac file' . PHP_EOL;
        continue;
    }

    $extension = strtolower(strrchr($object['Key'], '.'));
    // if ($extension === '.mov' || $extension === '.avi') {
    //     // we know that we don't want these ones without checking the MIME type below
    //     // (and takes a long time to download)
    //     echo 'ignoring mov or avi file' . PHP_EOL;
    //     continue;
    // }

    if (in_array($object['Key'], $objects_done_already)) {
        echo "already done.".PHP_EOL;
        continue;
    }

    try {
        if ($extension === '.jpg' || $extension === '.mov' || $extension === '.avi') {
            // echo "processing jpg" . PHP_EOL;
            $full_filepath = $s3_public_root.$object['Key'];
            // $metadata = exif_read_data($full_filepath);

            $this_album_name = substr($object['Key'], 0, strpos($object['Key'], '/'));
            // $dateTaken = isset($metadata['DateTime']) ? date('Y-m-d H:i:s', strtotime($metadata['DateTime'])) : date('Y-m-d H:i:s', strtotime('20'.substr($this_album_name, 0, 5).'-01'));
            if ($this_album_name !== $last_album_name) {
                $smug_album = array_key_exists($this_album_name, $smugmug_albums) ? $smugmug_albums[$this_album_name] : NULL;
                if (!$smug_album) {
                    $smug_album = $smug->albums_create('Title='.$this_album_name);
                    echo "(created new album '$this_album_name') ";
                }
                else {
                    echo '(using existing smugmug album) ';
                }
            }

            // var_dump($smug_album);
            $smug_photo = $smug->images_uploadFromURL(array(
                'AlbumID' => $smug_album['id'],
                'URL' => $full_filepath));
            echo "$full_filepath => ".(isset($smug_photo) ? $smug_photo['id'] : 'unk').PHP_EOL;

            $last_album_name = $this_album_name;

            $objects_done_already[] = $object['Key'];
        }
        else {
            echo "ignoring file with unknown extension".PHP_EOL;
        }
    }
    catch (Exception $e) {
        echo "bailing out with exception $e\n";
    }


    if ($i++ > 50)
        break;
}

file_put_contents($tmp_filepath.'smugmug_objects_done.txt', implode(PHP_EOL, $objects_done_already));
// file_put_contents($tmp_filepath.'db.json', json_format(json_encode($db)));

// function _fetch_smugmug_endpoint($url) {
//     // $oauth_record = $this->user_model->get_latest_OAuth($this->session->userdata('user_id'));

//     $oauth = new OAuth('Sm9RMHcRr1yRg5KBTf8w2wolJEBHTJDC', '6d3e325f90575631aa6bc9deec0e1d77');
//     $oauth->setToken($oauth_record->oauth_token, $oauth_record->oauth_token_secret);
//     log_message('info', "fetching URL at $url");
//     // $oauth->enableDebug();
//     $oauth->fetch($url, NULL, OAUTH_HTTP_METHOD_GET, array('x-li-format' => 'json'));
//     // log_message('debug', var_export($oauth->debugInfo, TRUE));

//     return json_decode($oauth->getLastResponse(), TRUE);
// }
// lifted from http://php.net/manual/en/function.json-encode.php#80339
function json_format($json)
{
    $tab = "  ";
    $new_json = "";
    $indent_level = 0;
    $in_string = false;

    $json_obj = json_decode($json);

    if($json_obj === false)
        return false;

    $json = json_encode($json_obj);
    $len = strlen($json);

    for($c = 0; $c < $len; $c++)
    {
        $char = $json[$c];
        switch($char)
        {
            case '{':
            case '[':
                if(!$in_string)
                {
                    $new_json .= $char . "\n" . str_repeat($tab, $indent_level+1);
                    $indent_level++;
                }
                else
                {
                    $new_json .= $char;
                }
                break;
            case '}':
            case ']':
                if(!$in_string)
                {
                    $indent_level--;
                    $new_json .= "\n" . str_repeat($tab, $indent_level) . $char;
                }
                else
                {
                    $new_json .= $char;
                }
                break;
            case ',':
                if(!$in_string)
                {
                    $new_json .= ",\n" . str_repeat($tab, $indent_level);
                }
                else
                {
                    $new_json .= $char;
                }
                break;
            case ':':
                if(!$in_string)
                {
                    $new_json .= ": ";
                }
                else
                {
                    $new_json .= $char;
                }
                break;
            case '"':
                if($c > 0 && $json[$c-1] != '\\')
                {
                    $in_string = !$in_string;
                }
            default:
                $new_json .= $char;
                break;                   
        }
    }

    return $new_json;
} 
?>
