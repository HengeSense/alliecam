<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

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
            $data['selected_album'] = $data['albums'][0];
        }

        $this->load->view('photo_viewer', $data);

    }

    function _get_data() {
        $data = json_decode(file_get_contents('application/models/db_all.json'), TRUE);
        return $data;
    }

    function _put_data($data) {
        $success = file_put_contents('application/models/db_all.json', json_encode($data));
        return $success;
    }

    function _add_to_album($album_name, $filename) {
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
            $db['albums'][] = &$add_album;
        }
        $add_album['photos'][] = array(
                'uniqid' => uniqid(),
                'caption' => 'None',
                'url' => "$album_name/$filename",
                );

        $assigned = ($add_album != NULL);
        $written = ($this->_put_data($db) !== FALSE);
        return $assigned && $written;
    }

    public function add() {
        // adds a photo to a named album
        // note: the photo doesn't come to this server, just an S3 filename
        $this->form_validation->set_rules('filename', 'filename', 'trim|required|xss_clean');
        $this->form_validation->set_rules('album_uniqid', 'album_uniqid', 'trim|xss_clean');
        if ($this->form_validation->run()) {
            $filename = $this->form_validation->set_value('filename');

            // TODO: ignored album
            $album_name = 'uploads';
            if ($this->_add_to_album($album_name, $filename)) {
                $this->output->set_status_header('200');
            }
            else {
                log_message('error', "failed to add '$filename' to '$album_name'");
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
}

/* End of file welcome.php */
/* Location: ./application/controllers/welcome.php */
