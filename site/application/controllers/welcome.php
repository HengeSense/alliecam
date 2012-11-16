<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Welcome extends CI_Controller {

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
        $this->photos();
    }

    public function photos($album_uniqid=NULL) {
        $data = json_decode(file_get_contents('application/models/db_test.json'), TRUE);
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

    public function add_photo() {
        // adds a photo to a named album
        // note: the photo doesn't come to this server, just an S3 filename

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
