---
date: 2017-03-04
slug: learning-tensorflow-with-crystal
title: Learning Tensorflow with Crystal
tags:
  - tensorflow
  - ai
  - crystal
  - bindings

section: story
image: /assets/images/stories/tensorflowcr.png
author: Michał Kalbarczyk
author_image: ../images/authors/michal.png
---

#### Crystal bindings for Tensorflow

In this article I’d like to describe:

- How to build a tensorflow library
- How to generate bindings for Crystal
- How to use tensorflow library in Crystal
- Share the results of my work: tensorflow.cr

## Useful Links

- Crystal language: https://crystal-lang.org/
- Crystal bindings generator: https://github.com/crystal-lang/crystal_lib
- Tensorflow: https://www.tensorflow.org/
- Tensorfow repository: https://github.com/tensorflow/tensorflow
- tensorflow.cr repository: https://github.com/fazibear/tensorflow.cr
- rensorflow.cr examples repository: https://github.com/fazibear/tensorflow.cr_examples

Install and build tensorflow
To install and compile tensorflow we will need to install all these things:

- bazel
- python
- numpy (python package)

At the beginning, we need to checkout whole tensorflow repository

```bash
$ git clone https://github.com/tensorflow/tensorflow
```

Next, we need to change directory and run configure

```bash
$ cd tensorflow
$ ./configure
```

We need to answer few questions about python and features that our compiled library will support. We can just hit enter. After that bazel will download all dependencies and setup all things.

We need to build only a library. Let’s do it.

```bash
$ cd tensorflow # yes! tensorflow/tensorflow
$ bazel build :libtensorflow.so
```

That’s hot. We got it. The last step, install it!

```bash
cp ../bazel-bin/tensorflow/libtensorflow.so /usr/local/lib/ libtensorflow.so
```

Library installed.

## Generating bindings

To work with the tensorflow library, we need to generate bindings. Crystal has an application for that. All you need to do is checkout [crystal_lib](https://github.com/crystal-lang/crystal_lib) and add the `lib_tensorflow.cr` file into examples directory. Remeber to replace `{tensorflow_dir}` with directory when you checked out tensorflow.

```crystal
@[Include(
  "tensorflow/c/c_api.h",
  flags: "
    -I/{tensorflow_dir}/tensorflow/
    -I/{tensorflow_dir}/tensorflow/bazel-genfiles
    -I/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/include/c++/v1
  ",
  prefix: %w(TF_ Tf)
)]
@[Link("tensorflow")]
lib LibTensorFlow
end
```

Now execute generator:

```bash
$ crystal src/main.cr -- examples/lib_tensorflow.cr
```

Done. We’ve got bindings. We can copy the output into our crystal project and start to mess up with tensorflow. Let’s name it `lib_tensorflow.cr`.

## Using tensorflow from crystal

Because tensorflow library doesn’t provide any easy ways to build the graph, we need to use python.

```python
import tensorflow as tf
with tf.Session() as sess:
    a = tf.Variable(5.0, name='a')
    b = tf.Variable(6.0, name='b')
    c = tf.multiply(a, b, name='c')
sess.run(tf.global_variables_initializer())
tf.train.write_graph(sess.graph_def, '.', 'graph.pb', as_text=False)
```

This simple script will generate a graph and save it into the `graph.pb` file.

We’ve generated the graph that needs two variables for input and returns one number. It’s multiplication of inputs. We’ve also named it as `a`, `b`, `c`.

Now let’s move to crystal. We need to require our bindings first.

```crystal
require 'lib_tensorflow'
```

Now we’re ready! We need to initialise a `session`:

```crystal
opts = LibTensorflow.new_session_options
status = LibTensorflow.new_status
graph = LibTensorflow.new_graph
session = LibTensorflow.new_session(graph, opts, status)
```

As you can see, we need a graph, options, and status. All of these can be done using the function from bindings. Also, we need to check if creating session was successful.

```crystal
puts LibTensorflow.get_code(status)
```

All we need to do is take a status and check its code. We’re using the function from bindings. The line above should print `Ok` if everything if fine. If it’s not, we can show more detailed error message like this:

```crystal
puts String.new(LibTensorflow.message(status))
```

If we have a session, we need to load a graph into.

```crystal
file = File.read("./graph.pb")
buffer = LibTensorflow.new_buffer_from_string(file, file.size)
import_opts = LibTensorflow.new_import_graph_def_options
LibTensorflow.graph_import_graph_def(graph, buffer, import_opts, status)
```

All we need is to read data from the file, create a buffer with a function from bindings, and pass buffer into function that will import our data.

Again we should remember to check if everything is fine:

```crystal
puts LibTensorflow.get_code(status)
```

Graph loaded. Now we need to create tensors. Tensors hold input and output data. Tensors will hold data.

One more thing, while initialisation tensor will need a deallocation function. We just create empty function. Creating proper function is beyond the scope of this article.

```crystal
deloc = ->(a : Pointer(Void), b : UInt64, c: Pointer(Void)) {}
```

Now we’re focus on inputs. We need two values. These are tensors for that:

```crystal
a_dims = [] of Int64
a_data = [3.0_f32] of Float32
a_tensor = LibTensorflow.new_tensor(
  LibTensorflow::Datatype::Float,
  a_dims, a_dims.size,
  a_data, a_data.size,
  deloc, nil)
b_dims = [] of Int64
b_data = [5.0_f32] of Float32
b_tensor = LibTensorflow.new_tensor(
  LibTensorflow::Datatype::Float,
  b_dims, b_dims.size,
  b_data, b_data.size,
  deloc, nil)
```

And empty one for output:

```crystal
c_dims = [] of Int64
c_data = [] of Float32
c_tensor = LibTensorflow.new_tensor(
   LibTensorflow::Datatype::Float,
   c_dims, c_dims.size,
   c_data, c_data.size,
   deloc, nil)
```

Another thing is operations. Operations take data from tensors and write data other tensors. Tensors variable is also operation so that we can read data from. We will need three operations. They are defined in graph. Remember `a`, `b`, `c`?

```crystal
i1 = LibTensorflow::Output.new
i1.oper = LibTensorflow.graph_operation_by_name(graph, "a")
i1.index = 0
i2 = LibTensorflow::Output.new
i2.oper = LibTensorflow.graph_operation_by_name(graph, "b")
i2.index = 0
o1 = LibTensorflow::Output.new
o1.oper = LibTensorflow.graph_operation_by_name(graph, "c")
o1.index = 0
```

To make code more readable, we create some variables for inputs and outputs:

```crystal
inputs = [i1, i2] of LibTensorflow::Output
input_values = [a_tensor, b_tensor] of LibTensorflow::X_Tensor
outputs = [o1] of LibTensorflow::Output
outputs_values = [c_tensor] of LibTensorflow::X_Tensor
```

Now we almost have all data require to run our graph, let’s do it:

```crystal
optss = LibTensorflow.new_buffer
meta = LibTensorflow.new_buffer
target = [] of LibTensorflow::X_Operation
LibTensorflow.session_run(session, nil,
                    inputs, input_values, inputs.size,
                    outputs, outputs_values, outputs.size,
                    target, target.size,
                    nil, status)
```

Yeah! Last check of status:

```crystal
puts LibTensorflow.get_code(status)
```

Where our output is? Sure, let’s take it from output tensor and print it:

```crystal
o = outputs_values[0]
out_data = LibTensorflow.tensor_data(o)
out_value = out_data.as(Float32*)
puts out_value.value
```

As tensor outputs can be different, we need to cast it to the proper value and follow a pointer.

Now we can run our program.

```bash
$ crystal src/ok.cr
```

After few `Ok` we’ve got `15` which is correct.

First success!

## What’s next?

Of course, It’s not the end. I want to learn more!

I’ve created [tensorflow.cr](https://github.com/fazibear/tensorflow.cr) project. For now, it is a simple bindings, but I’m working on a beautiful crystal DSL for library and create an ability to graph generation. It’s a fascinating way to learn how tensorflow works. If you’re interested in helping me with this project just let me know. I’ll be appreciated.

In part of that, there is also tensorflow.cr_examples repository. There is one that I was described in this article, and also other that will use crystal DSL (this part might not work during development process)
