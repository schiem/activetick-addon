### OS X
- brew install protobuf

### UBUNTU LINUX
- sudo apt-get install libprotobuf-dev protobuf-compiler

#### To-Do
  - Support every API method
  - Pass a callback for streaming updates, and the response to begin streaming updates
    - keep the streaming update callback alive for the duration
    - keep a separate libuv interrupter around
  - Memory Management
    - CPP: delete *pointer;
  - Usage documentation
  - Make node-version independent (using nan)
  
#### Repos Of Note
- https://github.com/maxto/ubique
- http://quantlib.org/index.shtml (c++)