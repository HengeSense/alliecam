<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>Allie Cam</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="">
    <meta name="author" content="">

    <!-- Le styles -->
    <link href="<?php echo base_url('static/css/bootstrap.css');?>" rel="stylesheet">
    <!--link href="<?php echo base_url();?>static/css/bootstrap-responsive.css" rel="stylesheet"-->
    <!--link href="<?php echo base_url('static/css/fonts.css');?>" rel="stylesheet"-->
    <!--link href="<?php echo base_url('static/css/alliecam.css');?>" rel="stylesheet"-->
    <style>
        body {
            padding-top: 60px; /* 60px to make the container go all the way to the bottom of the topbar */
        }
    </style>

    <!-- HTML5 shim, for IE6-8 support of HTML5 elements -->
    <!--[if lt IE 9]>
    <script src="http://html5shim.googlecode.com/svn/trunk/html5.js"></script>
    <![endif]-->

    <!-- Fav and touch icons -->
    <!--
    <link rel="shortcut icon" href="../assets/ico/favicon.ico">
    <link rel="apple-touch-icon-precomposed" sizes="144x144" href="../assets/ico/apple-touch-icon-144-precomposed.png">
    <link rel="apple-touch-icon-precomposed" sizes="114x114" href="../assets/ico/apple-touch-icon-114-precomposed.png">
    <link rel="apple-touch-icon-precomposed" sizes="72x72" href="../assets/ico/apple-touch-icon-72-precomposed.png">
    <link rel="apple-touch-icon-precomposed" href="../assets/ico/apple-touch-icon-57-precomposed.png">
    -->
<?php $ip = $this->input->ip_address(); if (!$this->input->valid_ip($ip) || $ip == '127.0.0.1'): ?>
    <script src="<?php echo base_url('static/js/jquery/1.7.1/jquery.js'); ?>" type="text/javascript"></script>
<?php else:?>
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js" type="text/javascript"></script>
    <!-- TODO: GOOGLE ANALYTICS CODE -->
<?php endif; ?>
</head>

<body>

    <div class="navbar navbar-inverse navbar-fixed-top">
        <div class="navbar-inner">
            <div class="container">
                <a class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
                    <span class="icon-bar"></span>
                    <span class="icon-bar"></span>
                    <span class="icon-bar"></span>
                </a>
                <a class="brand" href="#">Allie Cam</a>
                <div class="nav-collapse collapse">
                    <ul class="nav">
                        <li class="active"><a href="#">Home</a></li>
                        <li><a href="#about">About</a></li>
                    </ul>
                </div><!--/.nav-collapse -->
            </div>
        </div>
    </div>

    <div class="container">
    <div class="row">
        <div class="span3" id="sidebar">
            <div class="well sidebar-nav">
                <ul class="nav nav-list" id="ac_sidebar">
                    <li class="nav-header recipient">Albums</li>
                    <?php foreach ($albums as $album): ?>
                        <li id="<?php echo $album['uniqid'] ?>"><a href="<?php echo base_url('photos/album/'.$album['uniqid']) ?>"><?php echo $album['name'] ?></a></li>
                    <?php endforeach; ?>
                </ul>
            </div>
        </div>
        <div class="span9" id="maincontent">
            <div id="photo-carousel" class="carousel slide">
                <!-- Carousel items -->
                <div class="carousel-inner">
                <?php $isFirst = TRUE; foreach ($selected_album['photos'] as $photo): ?>
                    <div class="item <?php echo $isFirst ? 'active' : '' ?>">
                        <img alt="" src="<?php echo $home.$photo['url'] ?>">
                    </div>
                <?php $isFirst = FALSE; endforeach; ?>
                </div>
                <!-- Carousel nav -->
                <a class="carousel-control left" href="#photo-carousel" data-slide="prev">&lsaquo;</a>
                <a class="carousel-control right" href="#photo-carousel" data-slide="next">&rsaquo;</a>
            </div>
        </div>

<?php if (isset($sidebar_selection) && $sidebar_selection != ''): ?>
<script type="text/javascript">
    $(document).ready(function() {
        $('#ac_sidebar').children('#<?php echo $sidebar_selection; ?>').addClass("active");
    });
</script>
<?php endif; ?>


    </div> <!-- /container -->

    <!-- Le javascript
    ================================================== -->
    <!-- Placed at the end of the document so the pages load faster -->
    <script src="<?php echo base_url('static/js/bootstrap-transition.js'); ?>"></script>
    <script src="<?php echo base_url('static/js/bootstrap-alert.js'); ?>"></script>
    <script src="<?php echo base_url('static/js/bootstrap-modal.js'); ?>"></script>
    <script src="<?php echo base_url('static/js/bootstrap-dropdown.js'); ?>"></script>
    <script src="<?php echo base_url('static/js/bootstrap-scrollspy.js'); ?>"></script>
    <script src="<?php echo base_url('static/js/bootstrap-tab.js'); ?>"></script>
    <script src="<?php echo base_url('static/js/bootstrap-tooltip.js') ?>"></script>
    <script src="<?php echo base_url('static/js/bootstrap-popover.js') ?>"></script>
    <script src="<?php echo base_url('static/js/bootstrap-button.js') ?>"></script>
    <script src="<?php echo base_url('static/js/bootstrap-collapse.js') ?>"></script>
    <script src="<?php echo base_url('static/js/bootstrap-carousel.js') ?>"></script>
    <script src="<?php echo base_url('static/js/bootstrap-typeahead.js') ?>"></script>

</body>
</html>
