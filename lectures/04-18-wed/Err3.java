class A {}
class B {}

public class Err3 {
  public static void main(String[] args) {
    System.out.println("The line with print");

    Object a = new A();
    B b = (B)a;
    System.out.println("B: " + b.toString());
  }
}
