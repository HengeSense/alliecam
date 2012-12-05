<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

use Aws\Common\Aws;
use Aws\S3\Enum\CannedAcl;
use Guzzle\Http\EntityBody;

class Photos extends CI_Controller {

    function __construct() {
        parent::__construct();

        $this->load->library('form_validation');
    }
    /**
     * Index Page for this controller.
     *
     * Maps to the following URL
     * 		http://example.com/index.php/welcome
     *	- or -  
     * 		http://example.com/index.php/welcome/index
     *	- or -
     * Since this controller is set as the default controller in 
     * config/routes.php, it's displayed at http://example.com/
     *
     * So any other public methods not prefixed with an underscore will
     * map to /index.php/welcome/<method_name>
     * @see http://codeigniter.com/user_guide/general/urls.html
     */
    public function index()
    {
        // $this->load->view('welcome_message');
        log_message('info', 'loading home page');
        $this->album();
    }

    public function album($album_uniqid=NULL) {
        $data = $this->_get_data();
        uasort($data['albums'], function($album1, $album2) {
            if (!$album1 || !$album2)
                return 0;
            if (!isset($album1['dateCreated']) || !isset($album2['dateCreated']))
                return 0;

            return strtotime($album2['dateCreated']) - strtotime($album1['dateCreated']);
        });
        if (isset($album_uniqid)) {
            foreach($data['albums'] as $album) {
                if ($album['uniqid'] == $album_uniqid) {
                    $data['selected_album'] = $album;
                    break;
                }
            }
        }
        if (!isset($data['selected_album'])) {
            if (isset($album_uniqid))
                log_message('error', "could not find album $album_uniqid");
            $data['selected_album'] = reset($data['albums']);
        }

        $this->load->view('photo_viewer', $data);

    }

    function _get_data() {
        $data = json_decode(file_get_contents('application/models/db_all.json'), TRUE);
        // temp HACK
        // foreach ($data['albums'] as &$album) {
        //     foreach ($album['photos'] as &$photo) {
        //         $extension = strtolower(strrchr($photo['url'], ;
        //         $awspath_pre_extension = strstr($photo['url'], '.', TRUE);
        //         $photo['url_thumbnail'] = $awspath_pre_extension.'_thumb'.$extension; 
        //         $photo['url_fullsize'] = $photo['url'];
        //         $photo['url'] = $awspath_pre_extension.'_ac'.$extension; 
        //     }
        // }
        return $data;
    }

    function _put_data($data) {
        $success = file_put_contents('application/models/db_all.json', $this->_json_format(json_encode($data)));
        return $success;
    }

    function _add_to_album($album_name, $filename, $metadata = '') {
        log_message('info', "adding '$filename' to '$album_name'");
        $db = $this->_get_data();
        $add_album = NULL;
        foreach ($db['albums'] as &$album) {
            if (isset($album['name']) && $album['name'] == $album_name) {
                log_message('info', "found existing album called '$album_name'");
                $add_album = &$album;
                break;
            }
        }

        if (!$add_album) {
            log_message('info', "could not find album called '$album_name'... creating one");
            $add_album = array(
                'uniqid' => uniqid(),
                'name' => $album_name,
                'dateCreated' => date("Y-m-d H:i:s"),
                'photos' => array(),
                );
            // HACK: not sure if this ref assignment will work
            // testing indicates that it does
            $db['albums'][] = &$add_album;
        }

        require 'AWSSDKforPHP/aws.phar';
        include('application/libraries/resize-class.php');

        // Instantiate an S3 client
        $s3 = Aws::factory('aws_config.php')->get('s3');
        $bucket = 'blackwellfamily';
        $tmp_filepath = 'static/tmp/';

        $response = $s3->getObject(array(
            'Bucket' => $bucket,
            'Key' => $album_name.'/'.$filename,
            ));

        $filename_pre_extension = strstr($filename, '.', TRUE);
        $extension = strtolower(strrchr($filename, '.'));
        $full_filepath = $tmp_filepath.$filename_pre_extension.$extension;
        file_put_contents($full_filepath, $response['Body']);

        $resizer = new resize($full_filepath);

        // echo "resizing for alliecam.net use\n";
        $resizer->resizeImage(600, 600);
        $ac_filepath = $tmp_filepath.$filename_pre_extension.'_ac'.$extension;
        // echo "storing temporarily at $ac_filepath\n";
        $resizer->saveImage($ac_filepath, 70);

        // echo "putting in S3\n";
        $awspath_pre_extension = $album_name.'/'.$filename_pre_extension;
        $ac_awspath = $awspath_pre_extension.'_ac'.$extension; 
        try {
            $s3->putObject(array(
                'Bucket' => $bucket,
                'Key' => $ac_awspath,
                'ContentType' => $response['ContentType'],
                'Body' => EntityBody::factory(fopen($ac_filepath, 'r')),
                'ACL' => CannedACL::PUBLIC_READ
                ));
        } catch (Exception $e) {
            log_message('error', "ERROR: Could not upload $ac_awspath ($e)");
        }

        // echo "resizing for thumbnail use\n";
        $resizer->resizeImage(100, 100);
        $thumb_filepath = $tmp_filepath.$filename_pre_extension.'_thumb'.$extension;
        $resizer->saveImage($thumb_filepath, 50);

        // echo "putting in S3\n";
        $thumb_awspath = $awspath_pre_extension.'_thumb'.$extension; 
        try {
            $s3->putObject(array(
                'Bucket' => $bucket,
                'Key' => $thumb_awspath,
                'ContentType' => $response['ContentType'],
                'Body' => EntityBody::factory(fopen($thumb_filepath, 'r')),
                'ACL' => CannedACL::PUBLIC_READ
                ));
        } catch (Exception $e) {
            echo "ERROR: Could not upload $thumb_awspath ($e)\n";
        }

        // $dateTaken = isset($metadata['DateTime']) ? date('Y-m-d H:i:s', strtotime($metadata['DateTime'])) :
        //     date('Y-m-d H:i:s', strtotime('20'.substr($this_album_name, 0, 5).'-01'));
        $add_album['photos'][] = array(
                'uniqid' => uniqid(),
                'caption' => 'None',
                'url_fullsize' => "$album_name/$filename",
                'url' => $ac_awspath,
                'url_thumbnail' => $thumb_awspath,
                // 'dateTaken' => $dateTaken,
                'metadata' => $metadata,
                );

        $assigned = ($add_album != NULL);
        $written = ($this->_put_data($db) !== FALSE);
        return $assigned && $written;
    }

    public function add() {
        // adds a photo to a named album
        // note: the photo doesn't come to this server, just an S3 filename
        $this->form_validation->set_rules('filename', 'filename', 'trim|required|xss_clean');
        $this->form_validation->set_rules('albumname', 'albumname', 'trim|xss_clean');
        $this->form_validation->set_rules('metadata', 'metadata', 'trim|xss_clean');
        if ($this->form_validation->run()) {
            $filename = $this->form_validation->set_value('filename');
            $albumname = $this->form_validation->set_value('albumname', 'uploads');
            $metadata = $this->form_validation->set_value('metadata', '');

            // TODO: ignored album
            if ($this->_add_to_album($albumname, $filename, $metadata)) {
                $this->output->set_status_header('200');
            }
            else {
                log_message('error', "failed to add '$filename' to '$albumname'");
                $this->output->set_status_header('400');
            }
        }
    }

    public function edit_photo() {

    }
    public function move_photo() {

    }
    public function delete_photo() {
    }

    // lifted from http://php.net/manual/en/function.json-encode.php#80339
    function _json_format($json)
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
}

/* End of file welcome.php */
/* Location: ./application/controllers/welcome.php */
