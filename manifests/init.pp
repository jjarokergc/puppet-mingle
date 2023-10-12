# Class: mingle
#
#
class mingle {
  include mingle::build  # Prepare Build Environment
  include mingle::server # Deploy Mingle to Tomcat
  include mingle::config # Configure Mingle
}
