<?php
require 'AWSSDKforPHP/aws.phar';
include('resize-class.php');
use Aws\Common\Aws;
use Aws\S3\Enum\CannedAcl;
use Guzzle\Http\EntityBody;

// Instantiate an S3 client
$s3 = Aws::factory('application/config/aws_config.php')->get('s3');
$bucket = 'blackwellfamily';
$tmp_filepath = 'tmp/';
$fileroot = '*** network address ***/';

$i = 0;
$last_album_name = '';
$album = NULL;
$objects_done_already = file_exists($tmp_filepath.'db_objects_done.txt') ? explode(PHP_EOL, file_get_contents($tmp_filepath.'db_objects_done.txt')) : array();
$db = file_exists($tmp_filepath.'db.json') ? 
            json_decode(file_get_contents($tmp_filepath.'db.json')) :
            array(
                'owner'=> 'blackwellfamily',
                'home' => 'http://blackwellfamily.s3-website-ap-southeast-2.amazonaws.com/',
                'albums' => array(),
                );

foreach ($s3->getIterator('ListObjects', array('Bucket' => $bucket)) as $object) {
    echo $bucket . '/' . $object['Key'].'...';
    $awspath_pre_extension = strstr($object['Key'], '.', TRUE);
    if (substr_compare($awspath_pre_extension, '_ac', -3, 3) === 0 ||
            substr_compare($awspath_pre_extension, '_thumb', -6, 6) === 0) {
        echo 'ignoring existing thumb or ac file' . PHP_EOL;
        continue;
    }

    $extension = strtolower(strrchr($object['Key'], '.'));
    if ($extension === '.mov' || $extension === '.avi') {
        // we know that we don't want these ones without checking the MIME type below
        // (and takes a long time to download)
        echo 'ignoring mov or avi file' . PHP_EOL;
        continue;
    }

    if (in_array($object['Key'], $objects_done_already)) {
        echo "already done.\n";
        continue;
    }

    try {
        if ($extension === '.jpg') {
            echo "processing jpg" . PHP_EOL;
            $full_filepath = $fileroot.$object['Key'];
            // $metadata = exif_read_data($full_filepath);

            $this_album_name = substr($object['Key'], 0, strpos($object['Key'], '/'));
            $dateTaken = isset($metadata['DateTime']) ? date('Y-m-d H:i:s', strtotime($metadata['DateTime'])) : 
                date('Y-m-d H:i:s', strtotime('20'.substr($this_album_name, 0, 5).'-01'));
            if ($album === NULL || $this_album_name !== $last_album_name) {
                $db['albums'][] = array(
                    'uniqid' => uniqid(),
                    'dateCreated' => date('Y-m-d H:i:s', strtotime('20'.substr($this_album_name, 0, 5).'-01')),
                    'name' => substr($this_album_name, 6),
                    'photos' => array(),
                    );
                end($db['albums']);
                $last_album = &$db['albums'][key($db['albums'])];
                $album = &$last_album['photos'];
            }

            $ac_awspath = $awspath_pre_extension.'_ac'.$extension; 
            $thumb_awspath = $awspath_pre_extension.'_thumb'.$extension; 
            $dateTaken = isset($metadata['DateTime']) ? date('Y-m-d H:i:s', strtotime($metadata['DateTime'])) :
                date('Y-m-d H:i:s', strtotime('20'.substr($this_album_name, 0, 5).'-01'));
            $album[] = array(
                'uniqid' => uniqid(),
                'caption' => '',
                'url_fullsize' => $object['Key'],
                'url' => $ac_awspath,
                'url_thumbnail' => $thumb_awspath,
                'dateTaken' => $dateTaken,
                );
            $last_album_name = $this_album_name;

            $objects_done_already[] = $object['Key'];
        }
    }
    catch (Exception $e) {
        echo "bailing out with exception $e\n";
    }


    // if ($i++ > 3)
    //     break;
}

file_put_contents($tmp_filepath.'db_objects_done.txt', implode(PHP_EOL, $objects_done_already));
file_put_contents($tmp_filepath.'db.json', json_format(json_encode($db)));

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
