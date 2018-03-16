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

	test("Check that AABB1 has the right center", 
	()	{
			expect(AABB.center(new Float32List(2), aabb1), equals([2,2]));
		}
	);

	test("Copy", 
	()	{
			var a = AABB.copy(AABB.create(), aabb1);
			bool equals = a[0] == aabb1[0] && a[1] == aabb1[1] && a[2] == aabb1[2] && a[3] == aabb1[3];
			expect(true, equals);
		}
	);

	test("Clone", 
	()	{
			var a = AABB.clone(aabb1);
			bool equals = a[0] == aabb1[0] && a[1] == aabb1[1] && a[2] == aabb1[2] && a[3] == aabb1[3];
			expect(true, equals);
		}
	);

	test("Size", 
	()	{
			expect(AABB.size(new Float32List(2), aabb1), [4, 4]);
		}
	);

	test("Extents", 
	()	{
			expect(AABB.extents(new Float32List(2), aabb1), [2, 2]);
		}
	);

	test("Extents", 
	()	{
			expect(AABB.perimeter(aabb2), 8);
		}
	);

	test("Combine", 
	()	{
			var a = AABB.create();
			a[2] = 1.0;
			a[3] = 1.0;
			var b = AABB.create();
			b[0] = 0.5;
			b[1] = 0.5;
			b[2] = 2.0;
			b[3] = 2.0;

			expect(AABB.combine(AABB.create(), a,b), [0.0, 0.0, 2.0, 2.0]);
		}
	);
	
	test("AABB1 contains AABB2", 
	()	{
			expect(AABB.contains(aabb1, aabb2), equals(true));
		}
	);

	test("isValid", 
	()	{
			expect(AABB.isValid(aabb1), equals(true));
		}
	);
	
	test("is NOT Valid", 
	()	{
			var  a = new Float32List(4);
			a[0] = 4.5;
			a[1] = 4.0;
			a[2] = 3.5;
			a[3] = 1.0;
			expect(AABB.isValid(a), equals(false));
		}
	);
}