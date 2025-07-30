resource "aws_instance" "bastion_host" {
  ami                    = var.ami_id
  key_name               = "bastion"
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnets[1].id

  tags = {
    "Name" = "${var.project_name}-${var.project_env}-bastion-host"
  }
}

resource "aws_launch_template" "launch_template_webapp" {
  name                   = "${var.project_name}-${var.project_env}-template"
  instance_type          = "t2.micro"
  key_name               = "bastion"
  image_id               = data.aws_ami.latest_ami.image_id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  tags = {
    "Name" = "${var.project_name}-${var.project_env}-launch-template"
  }
}


/*resource "aws_instance" "web-app" {
  count                  = 3
  ami                    = var.ami_id
  key_name               = "bastion"
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  instance_type          = "t2.micro"
  user_data = file("userdata.sh")
  subnet_id              = aws_subnet.private_subnets[count.index].id

  tags = {
    "Name" = "${var.project_name}-${var.project_env}-web-app-${count.index}"
  }
}*/


resource "aws_autoscaling_group" "web-app-asg" {
  name                      = "${var.project_name}-${var.project_env}-asg"
  max_size                  = var.asg_sizes["max_size"]
  min_size                  = var.asg_sizes["min_size"]
  health_check_grace_period = 120
  health_check_type         = "ELB"
  desired_capacity          = var.asg_sizes["desired_capacity"]
  vpc_zone_identifier       = aws_subnet.private_subnets[*].id

  launch_template {
    id      = aws_launch_template.launch_template_webapp.id
    version = aws_launch_template.launch_template_webapp.latest_version
  }
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 120
    }
  }
  tag {
    key                 = "Environment"
    value               = var.project_env
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.project_env}-instance"
    propagate_at_launch = true
  }
}



resource "aws_lb_target_group" "alb-target-group" {
  name     = "${var.project_name}${var.project_env}TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.app_vpc.id
  health_check {
    path                = "/health.html"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 20
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2

  }
}

resource "aws_autoscaling_attachment" "asg_tg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.web-app-asg.id
  lb_target_group_arn    = aws_lb_target_group.alb-target-group.arn
}


resource "aws_lb" "web-alb" {
  name     = "${var.project_name}${var.project_env}webALB"
  internal = false

  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public_subnets[*].id

  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-${var.project_env}webALB"
  }
}

resource "aws_lb_listener" "load_balancer_listner_https" {
  load_balancer_arn = aws_lb.web-alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.load_balancer_acm.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-target-group.arn
  }
}

resource "aws_lb_listener" "loadbalancer_http_listner" {
  load_balancer_arn = aws_lb.web-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_route53_record" "route53-alias" {
  zone_id = data.aws_route53_zone.my_domain.zone_id
  name    = "${var.project_name}-${var.project_env}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.web-alb.dns_name
    zone_id                = aws_lb.web-alb.zone_id
    evaluate_target_health = true
  }
}
