---
date: 2008-01-14
slug: echo2-with-jruby
title: Echo2 with JRuby
tags:
  - ruby
  - java
  - jruby

section: story
image: /assets/images/stories/archived.jpg
author: Michał Kalbarczyk
author_image: ../images/authors/michal.png
---

I want to play with jruby, and I rewrite a numberguess example application from [Echo2](http://echo.nextapp.com/site/echo2) framework into Ruby using JRuby.
Let's see...
First we need to rewrite a NumberGuessServlet to load a NumberGuessApp ruby class instead of java class.

```java
public class NumberGuessServlet extends WebContainerServlet {

    Ruby runtime = Ruby.getDefaultInstance();

    public NumberGuessServlet() {
      super();

      StringBuffer script = new StringBuffer();
      URL url = NumberGuessServlet.class.getResource("NumberGuessApp.rb");
      URI uri;

      try {
        uri = new URI(url.getFile());
        File file = new File(uri.getPath());

        BufferedReader fin = new BufferedReader(new FileReader(file));
        String line = null;

        while ((line = fin.readLine()) != null) {
          script.append(line+"\n");
        }
        fin.close();

      } catch (URISyntaxException e) {
          e.printStackTrace();
      } catch (ArrayIndexOutOfBoundsException e){
          e.printStackTrace();
      } catch (IOException e){
          e.printStackTrace();
      }

      try {
        runtime.evalScript(script.toString());
      } catch (Exception e) {
        e.printStackTrace();
      }

    }


    /**
     * @see nextapp.echo2.webcontainer.WebContainerServlet#newApplicationInstance()
     */
    public ApplicationInstance newApplicationInstance() {

      Object numberGuessApp = runtime.evalScript("NumberGuessApp.new");
      numberGuessApp = org.jruby.javasupport.JavaEmbedUtils.rubyToJava(runtime,
                (org.jruby.runtime.builtin.IRubyObject) numberGuessApp, ApplicationInstance.class);

      return (ApplicationInstance) numberGuessApp;
    }

}
```

Now we have to write a ruby class.
Create a `NumberGuessApp.rb` and include a Java magic

```java
include Java
```

This make all Java stuff avaiable in ruby.
Next we need to include Echo2 stuff.

```ruby
module Echo2
  include_class 'nextapp.echo2.app.ApplicationInstance'
  include_class 'nextapp.echo2.app.Button'
  include_class 'nextapp.echo2.app.Color'
  include_class 'nextapp.echo2.app.ContentPane'
  include_class 'nextapp.echo2.app.Extent'
  include_class 'nextapp.echo2.app.Insets'
  include_class 'nextapp.echo2.app.Label'
  include_class 'nextapp.echo2.app.ResourceImageReference'
  include_class 'nextapp.echo2.app.Column'
  include_class 'nextapp.echo2.app.TextField'
  include_class 'nextapp.echo2.app.Window'
  include_class 'nextapp.echo2.app.event.ActionEvent'
  include_class 'nextapp.echo2.app.event.ActionListener'
  include_class 'nextapp.echo2.app.layout.ColumnLayoutData'
end
```

This makes all Echo2 lib namespaced. Don't forget to prefix Echo2 classes with Echo2::.
Next big thing is casts. We can't make a cast in ruby. But we can make something like this.
We need a NumberGuessApp instance, lets make a simple method that return it:

```ruby
class NumberGuessApp < Echo2::ApplicationInstance
  def self.instance
    @@instance
  end

  def init
    @@instance = self
  end
end
```

now instead of this:

```java
((NumberGuessApp) ApplicationInstance.getActive())
```

we can write:

```ruby
NumberGuessApp.instance
```

getActive() method propably do something more, but this is enough for this app.
Nice feature of JRuby is that we can change all method and variables names to fit ruby style, don't need to use any setters and getters.
For example you can write:

```ruby
@window.title = "Echo2 Guess-A-Number"
layout_column.cell_spacing = Echo2::Extent.new(10)
submit_button.add_action_listener(self)
```

But there is one problem. All methods that overrides included interfaces need to have a java names:

```ruby
def actionPerformed(event)
end
```

Take a look at CongratulationsPane. Constructor have an argument, but it's don't want to work with jruby. We have to delete it. There will be no information about number of tries on congratulation screen. Sorry :)
All variables are initialized in constructor (initialize method). For example:

```ruby
  def initialize

    #
    # Randomly generated number between 1 and 100 inclusive.
    #
    @random_number = rand 100
  end
```

Static variables like colors should looks like this:

```ruby
@guess_entry_field.foreground = Echo2::Color::WHITE
```

All source files are [here](http://fazibear.googlepages.com/echo2_numberguess.tar.gz).
If you want to run it download all required jar files and copy it to lib.

- [JRuby 1.0.3](http://repo1.maven.org/maven2/org/jruby/jruby-complete/1.0.3/jruby-complete-1.0.3.jar)
- [Servlet Api 2.4](http://mirrors.ibiblio.org/pub/mirrors/maven2/servletapi/servlet-api/2.4/servlet-api-2.4.jar)
- Echo2_App.jar
- Echo2_WebContainer.jar
- Echo2_WebRender.jar

Echo2 files are from [echo2](http://download.nextapp.com/downloads/echo2/2.0.0/NextApp_Echo2.tgz) package.
Start ant.
Copy a war file into your application server and launch it.
