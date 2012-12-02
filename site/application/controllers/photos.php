<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Photos extends CI_Controller {

    function __construct() {
        parent::__construct();
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
        $data = json_decode(file_get_contents('application/models/db_all.json'), TRUE);
        uasort($data['albums'], function($album1, $album2) {
            if (!$album1 || !$album2)
                return 0;
            if (!isset($album1['dateCreated']) || !isset($album2['dateCreated']))
                return 0;

            return strtotime($album1['dateCreated']) - strtotime($album2['dateCreated']);
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

    function _add_to_album($album_name, $filename) {
        $db = $this->_get_data();
        $assigned = FALSE;
        foreach ($db['albums'] as $album) {
            if (isset($album['name']) && $album['name'] == $album_name) {
                $album['photos'][] = array(
                    'uniqid' => uniqid(),
                    'caption' => 'None',
                    'url' => "$album_name/$filename",
                    );
                $assigned = TRUE;
                break;
            }
        }

        if (!$assigned) {
            $new_album = array(
                'uniqid' => uniqid(),
                'name' => $album_name,
                'dateCreated' => date("Y-m-d H:i:s"),
                'photos' => array(
                    'uniqid' => uniqid(),
                    'caption' => 'None',
                    'url' => "$album_name/$filename",
                    ),
                );
            $db['albums'][] = $new_album;
            $assigned = TRUE;
        }

        return $assigned;
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
