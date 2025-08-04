import 'dart:ui';

class Node {
  String id;
  String text;
  Offset position;
  Node? next;

  Node({
    required this.id,
    required this.text,
    required this.position,
    this.next,
  });
}

class NodeLinkedList {
  Node? head;
  int _length = 0;

  int get length => _length;

  void add(Node node) {
    if (head == null) {
      head = node;
    } else {
      Node current = head!;
      while (current.next != null) {
        current = current.next!;
      }
      current.next = node;
    }
    _length++;
  }

  void remove(String id) {
    if (head == null) return;

    if (head!.id == id) {
      head = head!.next;
      _length--;
      return;
    }

    Node? current = head;
    while (current!.next != null) {
      if (current.next!.id == id) {
        current.next = current.next!.next;
        _length--;
        return;
      }
      current = current.next;
    }
  }

  Node? findById(String id) {
    Node? current = head;
    while (current != null) {
      if (current.id == id) {
        return current;
      }
      current = current.next;
    }
    return null;
  }

  List<Node> toList() {
    List<Node> nodes = [];
    Node? current = head;
    while (current != null) {
      nodes.add(current);
      current = current.next;
    }
    return nodes;
  }
}
