import "package:test/test.dart";
import "../lib/src/tree.dart";
import 'dart:typed_data';

void main()
{
	Float32List aabb1 = AABB.create();
	aabb1[2] = 4.0;
	aabb1[3] = 4.0;

	Float32List aabb2 = AABB.create();	
	aabb2[0] = 1.0;
	aabb2[1] = 1.0;
	aabb2[2] = 3.0;
	aabb2[3] = 3.0;
		
	var tree = new Tree();
	int id;
	test("Create a new tree with only a root node", 
	() {
			id = tree.createProxy(aabb1, "Test_0");
			expect(tree.computeHeight(null), equals(0));
  		}
	);
		
	test("Correct RootId", 
	() {
			expect(id, equals(0));
  		}
	);

	test("Add another child", 
	() {
			id = tree.createProxy(aabb2, "Test_1");
			expect(id, equals(1));
  		}
	);
	
	test("Print everything", 
	() {
			tree.all(
				(int id, String item) {
				print("${id}: ${item}");
				return true;
			});
			expect(true, equals(true));
  		}
	);

}