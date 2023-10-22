import std.range;
import std.stdio;

void main(string[] args) {
    foreach (argc, argv; args.enumerate)
        writefln("argv[%d] = <%s>", argc, argv);
    while (true) {
    }
}
