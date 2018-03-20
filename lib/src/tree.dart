import 'dart:collection';
import "dart:typed_data";
import "dart:math";

const int AABBExtension = 10;
const double AABBMultiplier = 2.0;

typedef bool QueryCallback<T>(int id, T userData);

/// Float32List containing the coordinates of the Axis-Aligned Bounding Box of an object. 
/// Coordinates are stored as [x1, y1, x2, y2]
class AABB
{
	Float32List _buffer;

	Float32List get values
	{
		return _buffer;
	}

	AABB()
	{
		this._buffer = new Float32List.fromList([0.0, 0.0, 0.0, 0.0]);
	}

	AABB.clone(AABB a)
	{
		this._buffer = new Float32List.fromList(a.values);
	}

	AABB.fromValues(double a, double b, double c, double d)
	{
		_buffer = new Float32List.fromList([a, b, c, d]);
	}

	double operator[](int idx)
	{
		return this._buffer[idx];
	}

	operator[]=(int idx, double v)
	{
		this._buffer[idx] = v;
	}

	static AABB copy(AABB out, AABB a)
	{
		out[0] = a[0];
		out[1] = a[1];
		out[2] = a[2];
		out[3] = a[3];
		return out;
	}

	static Float32List center(Float32List out, AABB a)
	{
		out[0] = (a[0] + a[2]) * 0.5;
		out[1] = (a[1] + a[3]) * 0.5;
		return out;
	}

	static Float32List size(Float32List out, AABB a)
	{
		out[0] = a[2] - a[0];
		out[1] = a[3] - a[1];
		return out;
	}

	static Float32List extents(Float32List out, AABB a)
	{
		out[0] = (a[2] - a[0]) * 0.5;
		out[1] = (a[3] - a[1]) * 0.5;
		return out;
	}

	static double perimeter(AABB a)
	{
		double wx = a[2] - a[0];
		double wy = a[3] - a[1];
		return 2.0 * (wx + wy);
	}

	static AABB combine(AABB out, AABB a, AABB b)
	{
		out[0] = min(a[0], b[0]);
		out[1] = min(a[1], b[1]);
		out[2] = max(a[2], b[2]);
		out[3] = max(a[3], b[3]);
		return out;
	}

	static bool contains(AABB a, AABB b)
	{
		return a[0] <= b[0] && a[1] <= b[1] && b[2] <= a[2] && b[3] <= a[3];
	}

	static bool isValid(AABB a)
	{
		double dx = a[2] - a[0];
		double dy = a[3] - a[1];
		return dx >= 0 && dy >= 0 && a[0] <= double.MAX_FINITE && a[1] <= double.MAX_FINITE && a[2] <= double.MAX_FINITE && a[3] <= double.MAX_FINITE;
	}

	@override
	String toString()
	{
		return _buffer.toString();
	}
}

const int NullNode = -1;

class TreeNode<T>
{
	int _parentOrNext = 0;
	int _child1 = NullNode;
	int _child2 = NullNode;
	AABB _AABB = new AABB();
	int _height = -1;
	T _userData;

	TreeNode();

	AABB get BB
	{
		return this._AABB;
	}

	int get child1
	{
		return this._child1;
	}

	set child1(int n)
	{
		this._child1 = n;
	}

	int get child2
	{
		return this._child2;
	}

	set child2(int n)
	{
		this._child2 = n;
	}

	int get height
	{
		return this._height;
	}

	set height(int h)
	{
		this._height = h;
	}

	bool get isLeaf
	{
		return this._child1 == NullNode;
	}

	int get next
	{
		return this._parentOrNext;
	}

	set next(int n)
	{
		this._parentOrNext = n;
	}

	int get parent
	{
		return this._parentOrNext;
	}

	set parent(n)
	{
		this._parentOrNext = n;
	}

	T get userData
	{
		return this._userData;
	}

	set userData(T t)
	{
		this._userData = t;
	}
}

class Tree<T>
{
	int _root = NullNode;
	int _capacity = 0;
	int _nodeCount = 0;
	List<TreeNode> _nodes = [];
	int _freeNode = 0;

	Tree()
	{
		this.allocateNodes();
	}

	allocateNodes()
	{
		List<TreeNode> list = this._nodes;
		this._freeNode = this._nodeCount;

		if(this._capacity == 0)
		{
			this._capacity = 16;
		}
		else
		{
			this._capacity *= 2;
		}
		int count = this._capacity;
		for(int i = this._nodeCount; i < count; i++)
		{
			TreeNode node = new TreeNode();
			node.next = list.length + 1;
			list.add(node);
		}
		list[list.length - 1].next = NullNode;
	}

	int allocateNode()
	{
		if(this._freeNode == NullNode)
		{
			this.allocateNodes();
		}

		int nodeId = this._freeNode;
		TreeNode node = this._nodes[nodeId];
		this._freeNode = node.next;
		node.parent = NullNode;
		node.child1 = NullNode;
		node.child2 = NullNode;
		node.height = 0;
		node.userData = null;
		this._nodeCount++;
		return nodeId;
	}

	freeNode(nodeId)
	{
		if(nodeId < 0 || nodeId >= this._capacity)
		{
			throw new RangeError.range(nodeId, 0, this._capacity, "NodeID", "Out of bounds!");
		}
		if(this._nodeCount <= 0)
		{
			throw new StateError("Node count is not valid");
		}

		TreeNode node = this._nodes[nodeId];
		node.next = this._freeNode;
		node.userData = null;
		node.height = -1;
		this._freeNode = nodeId;
		this._nodeCount--;
	}

	int createProxy(AABB aabb, T userData)
	{
		int proxyId = this.allocateNode();
		TreeNode node = this._nodes[proxyId];
		node.BB[0] = aabb[0] - AABBExtension;
		node.BB[1] = aabb[1] - AABBExtension;
		node.BB[2] = aabb[2] + AABBExtension;
		node.BB[3] = aabb[3] + AABBExtension;
		node.userData = userData;
		node.height = 0;

		this.insertLeaf(proxyId);

		return proxyId;
	}

	destroyProxy(int proxyId)
	{
		if(proxyId < 0 || proxyId >= this._capacity)
		{
			throw new RangeError.range(proxyId, 0, this._capacity, "proxyId", "Out of bounds!");
		}

		TreeNode node = this._nodes[proxyId];
		if(!node.isLeaf)
		{
			throw new StateError("Node is not a leaf!");
		}

		this.removeLeaf(proxyId);
		this.freeNode(proxyId);
	}

	bool placeProxy(int proxyId, AABB aabb)
	{
		if(proxyId == null || proxyId < 0 || proxyId >= this._capacity)
		{
			throw new RangeError.range(proxyId, 0, this._capacity, "proxyId", "Out of bounds!");
		}

		TreeNode node = this._nodes[proxyId];
		if(!node.isLeaf)
		{
			throw new StateError("Node is not a leaf!");
		}

		if(AABB.contains(node.BB, aabb))
		{
			return false;
		}

		this.removeLeaf(proxyId);

		AABB extended = new AABB.clone(aabb);
		extended[0] = aabb[0] - AABBExtension;
		extended[1] = aabb[1] - AABBExtension;
		extended[2] = aabb[2] + AABBExtension;
		extended[3] = aabb[3] + AABBExtension;
		AABB.copy(node.BB, extended);

		this.insertLeaf(proxyId);
		return true;
	}

	bool moveProxy(int proxyId, AABB aabb, AABB displacement)
	{
		if(proxyId < 0 || proxyId >= this._capacity)
		{
			throw new RangeError.range(proxyId, 0, this._capacity, "proxyId", "Out of bounds!");
		}

		TreeNode node = this._nodes[proxyId];
		if(!node.isLeaf)
		{
			throw new StateError("Node is not a leaf!");
		}

		if(AABB.contains(node.BB, aabb))
		{
			return false;
		}

		this.removeLeaf(proxyId);

		AABB extended = new AABB.clone(aabb);
		extended[0] = aabb[0] - AABBExtension;
		extended[1] = aabb[1] - AABBExtension;
		extended[2] = aabb[2] + AABBExtension;
		extended[3] = aabb[3] + AABBExtension;

		double dx = AABBMultiplier * displacement[0];
		double dy = AABBMultiplier * displacement[1];

		if(dx < 0.0)
		{
			extended[0] += dx;
		}
		else
		{
			extended[2] += dx;
		}

		if(dy < 0.0)
		{
			extended[1] += dy;
		}
		else
		{
			extended[3] += dy;
		}

		AABB.copy(node.BB, extended);

		this.insertLeaf(proxyId);
		return true;
	}

	insertLeaf(int leaf)
	{
		List<TreeNode> nodes = this._nodes;

		if(this._root == NullNode)
		{
			this._root = leaf;
			nodes[this._root].parent = NullNode;
			return;
		}

		// Find the best sibling for this node
		AABB leafAABB = nodes[leaf].BB;
		int index = this._root;
		
		while(nodes[index].isLeaf == false)
		{
			int child1 = nodes[index].child1;
			int child2 = nodes[index].child2;

			double area = AABB.perimeter(nodes[index].BB);

			AABB combinedAABB = AABB.combine(new AABB(), nodes[index].BB, leafAABB);
			double combinedArea = AABB.perimeter(combinedAABB);

			// Cost of creating a new parent for this node and the new leaf
			double cost = 2.0 * combinedArea;

			// Min cost of pushing the leaf further down the tree
			double inheritanceCost = 2.0 * (combinedArea - area);

			// Cost of descending into child1
			double cost1;
			if(nodes[child1].isLeaf)
			{
				AABB aabb = AABB.combine(new AABB(), leafAABB, nodes[child1].BB);
				cost1 = AABB.perimeter(aabb) + inheritanceCost;
			}
			else
			{
				AABB aabb = AABB.combine(new AABB(), leafAABB, nodes[child1].BB);
				double oldArea = AABB.perimeter(nodes[child1].BB);
				double newArea = AABB.perimeter(aabb);
				cost1 = (newArea - oldArea) + inheritanceCost;
			}

			double cost2;
			if(nodes[child2].isLeaf)
			{
				AABB aabb = AABB.combine(new AABB(), leafAABB, nodes[child2].BB);
				cost2 = AABB.perimeter(aabb) + inheritanceCost;
			}
			else
			{
				AABB aabb = AABB.combine(new AABB(), leafAABB, nodes[child2].BB);
				double oldArea = AABB.perimeter(nodes[child2].BB);
				double newArea = AABB.perimeter(aabb);
				cost2 = (newArea - oldArea) + inheritanceCost;
			}

			// Descend according to the min cost
			if(cost < cost1 && cost < cost2)
			{
				break;
			}

			// Descend
			if(cost1 < cost2)
			{
				index = child1;
			}
			else
			{
				index = child2;
			}
		}

		int sibling = index;

		// Create new parent
		int oldParent = nodes[sibling].parent;
		int newParent = this.allocateNode();
		nodes[newParent].parent = oldParent;
		nodes[newParent].userData = null;
		AABB.combine( nodes[newParent].BB, leafAABB, nodes[sibling].BB);
		nodes[newParent].height = nodes[sibling].height + 1;

		if(oldParent != NullNode)
		{
			// The sibling was not the root
			if(nodes[oldParent].child1 == sibling)
			{
				nodes[oldParent].child1 = newParent;
			}
			else
			{
				nodes[oldParent].child2 = newParent;
			}

			nodes[newParent].child1 = sibling;
			nodes[newParent].child2 = leaf;
			nodes[sibling].parent = newParent;
			nodes[leaf].parent = newParent;
		}
		else
		{
			// The sibling was the root
			nodes[newParent].child1 = sibling;
			nodes[newParent].child2 = leaf;
			nodes[sibling].parent = newParent;
			nodes[leaf].parent = newParent;
			this._root = newParent;
		}

		// Walk back up the tree fixing heights and AABBs
		index = nodes[leaf].parent;
		while(index != NullNode)
		{
			index = this.balance(index);

			int child1 = nodes[index].child1;
			int child2 = nodes[index].child2;
			
			if(child1 == NullNode)
			{
				throw new StateError("Child1 is NULL!");
			}
			if(child2 == NullNode)
			{
				throw new StateError("Child2 is NULL!");
			}

			nodes[index].height = 1 + max(nodes[child1].height, nodes[child2].height);
			AABB.combine(nodes[index].BB, nodes[child1].BB, nodes[child2].BB);

			index = nodes[index].parent;
		}
	}

	removeLeaf(int leaf)
	{
		if(leaf == this._root)
		{
			this._root = NullNode;
			return;
		}

		List<TreeNode> nodes = this._nodes;

		int parent = nodes[leaf].parent;
		int grandParent = nodes[parent].parent;
		int sibling;

		if(nodes[parent].child1 == leaf)
		{
			sibling = nodes[parent].child2;
		}
		else
		{
			sibling = nodes[parent].child1;
		}

		if(grandParent != NullNode)
		{
			// Destroy parent and connect sibling to grandParent
			if(nodes[grandParent].child1 == parent)
			{
				nodes[grandParent].child1 = sibling;
			}
			else
			{
				nodes[grandParent].child2 = sibling;
			}

			nodes[sibling].parent = grandParent;
			this.freeNode(parent);

			// Adjust ancestor bounds

			int index = grandParent;
			while(index != NullNode)
			{
				index = this.balance(index);

				int child1 = nodes[index].child1;
				int child2 = nodes[index].child2;

				AABB.combine(nodes[index].BB, nodes[child1].BB, nodes[child2].BB);
				nodes[index].height = 1 + max(nodes[child1].height, nodes[child2].height);

				index = nodes[index].parent;
			}
		}
		else
		{
			this._root = sibling;
			nodes[sibling].parent = NullNode;
			this.freeNode(parent);
		}
	}

	// Perform a left or right rotation if node A is imbalanced
	// Returns the new root index
	int balance(iA)
	{
		if(iA == NullNode)
		{
			throw new StateError("iA should not be Null!");
		}

		List<TreeNode> nodes = this._nodes;
		TreeNode A = nodes[iA];
		if(A.isLeaf || A.height < 2)
		{
			return iA;
		}

		int iB = A.child1;
		int iC = A.child2;

		if(iB < 0 || iB >= this._capacity)
		{
			throw new RangeError.range(iB, 0, this._capacity, "iB", "Out of bounds!");
		}
		if(iC < 0 || iC >= this._capacity)
		{
			throw new RangeError.range(iC, 0, this._capacity, "iC", "Out of bounds!");
		}

		TreeNode B = nodes[iB];
		TreeNode C = nodes[iC];

		int balance = C.height - B.height;

		// Rotate C up
		if(balance > 1)
		{
			int iF = C.child1;
			int iG = C.child2;
			TreeNode F = nodes[iF];
			TreeNode G = nodes[iG];

			if(iF < 0 || iF >= this._capacity)
			{
				throw new RangeError.range(iF, 0, this._capacity, "iF", "Out of bounds!");
			}
			if(iG < 0 || iG >= this._capacity)
			{
				throw new RangeError.range(iG, 0, this._capacity, "iG", "Out of bounds!");
			}

			// Swap A and C
			C.child1 = iA;
			C.parent = A.parent;
			A.parent = iC;

			// A's old parent should point to C
			if(C.parent != NullNode)
			{
				if(nodes[C.parent].child1 == iA)
				{
					nodes[C.parent].child1 = iC;
				}
				else
				{
					if(nodes[C.parent].child2 != iA)
					{
						throw new StateError("Bad child2");
					}
					nodes[C.parent].child2 = iC;
				}
			}
			else
			{
				this._root = iC;
			}

			// Rotate
			if(F.height > G.height)
			{
				C.child2 = iF;
				A.child2 = iG;
				G.parent = iA;
				AABB.combine(A.BB, B.BB, G.BB);
				AABB.combine(C.BB,A.BB,F.BB);

				A.height = 1 + max(B.height, G.height);
				C.height = 1 + max(A.height, F.height);
			}
			else
			{
				C.child2 = iG;
				A.child2 = iF;
				F.parent = iA;
				AABB.combine(A.BB, B.BB, F.BB);
				AABB.combine(C.BB, A.BB, G.BB);

				A.height = 1 + max(B.height, F.height);
				C.height = 1 + max(A.height, G.height);
			}

			return iC;
		}

		// Rotate B up
		if(balance < -1)
		{
			int iD = B.child1;
			int iE = B.child2;
			TreeNode D = nodes[iD];
			TreeNode E = nodes[iE];

			if(iD < 0 || iD >= this._capacity)
			{
				throw new RangeError.range(iD, 0, this._capacity, "iD", "Out of bounds!");
			}
			if(iE < 0 || iE >= this._capacity)
			{
				throw new RangeError.range(iE, 0, this._capacity, "iE", "Out of bounds!");
			}

			// Swap A and B
			B.child1 = iA;
			B.parent = A.parent;
			A.parent = iB;

			// A's old parent should point to B
			if(B.parent != NullNode)
			{
				if(nodes[B.parent].child1 == iA)
				{
					nodes[B.parent].child1 = iB;
				}
				else
				{
					if(nodes[B.parent].child2 != iA)
					{
						throw new StateError("Bad child2, expected equal iA: ${iA}");
					}
					nodes[B.parent].child2 = iB;
				}
			}
			else
			{
				this._root = iB;
			}

			// Rotate
			if(D.height > E.height)
			{
				B.child2 = iD;
				A.child1 = iE;
				E.parent = iA;
				AABB.combine(A.BB, C.BB, E.BB);
				AABB.combine(B.BB, A.BB, D.BB);

				A.height = 1 + max(C.height, E.height);
				B.height = 1 + max(A.height, D.height);
			}
			else
			{
				B.child2 = iE;
				A.child1 = iD;
				D.parent = iA;
				AABB.combine(A.BB, C.BB, D.BB);
				AABB.combine(B.BB, A.BB, E.BB);

				A.height = 1 + max(C.height, D.height);
				B.height = 1 + max(A.height, E.height);
			}

			return iB;
		}

		return iA;
	}

	int getHeight()
	{
		if(this._root == NullNode)
		{
			return 0;
		}

		return this._nodes[this._root].height;
	}

	double getAreaRatio()
	{
		if(this._root == NullNode)
		{
			return 0.0;
		}

		List<TreeNode> nodes = this._nodes;
		TreeNode root = nodes[this._root];
		double rootArea = AABB.perimeter(root.BB);

		double totalArea = 0.0;
		int capacity = this._capacity;
		for(int i = 0; i < capacity; i++)
		{
			TreeNode node = nodes[i];
			if(node.height < 0)
			{
				continue;
			}

			totalArea += AABB.perimeter(node.BB);
		}

		return totalArea / rootArea;
	}

	// Compute the height of a subtree
	int computeHeight(int nodeId)
	{
		if(nodeId == null)
		{
			nodeId = this._root;
		}

		if(nodeId < 0 || nodeId >= this._capacity)
		{				
			throw new RangeError.range(nodeId, 0, this._capacity, "nodeId", "Out of bounds!");
		}
		TreeNode node = this._nodes[nodeId];

		if(node.isLeaf)
		{
			return 0;
		}

		int height1 = this.computeHeight(node.child1);
		int height2 = this.computeHeight(node.child2);
		return 1 + max(height1, height2);
	}

	validateStructure(int index)
	{
		if(index == NullNode)
		{
			return;
		}

		List<TreeNode> nodes = this._nodes;
		if(index == this._root)
		{
			if(nodes[index].parent != NullNode)
			{
				throw new StateError("Expected parent to be null!");
			}
		}

		TreeNode node = nodes[index];
		int child1 = node.child1;
		int child2 = node.child2;

		if(node.isLeaf)
		{
			if(child1 != NullNode)
			{
				throw new StateError("Expected child1 to be null!");
			}
			if(child2 != NullNode)
			{
				throw new StateError("Expected child2 to be null!");
			}
			if(node.height != 0)
			{
				throw new StateError("Expected node's height to be 0!");
			}
			return;
		}

		if(child1 < 0 || child1 >= this._capacity)
		{				
			throw new RangeError.range(child1, 0, this._capacity, "child1", "Out of bounds!");
		}
		if(child2 < 0 || child2 >= this._capacity)
		{				
			throw new RangeError.range(child2, 0, this._capacity, "child2", "Out of bounds!");
		}

		if(nodes[child1].parent != index)
		{
			throw new StateError("Expected child1 parent to be ${index}");
		}
		if(nodes[child2].parent != index)
		{
			throw new StateError("Expected child2 parent to be ${index}");
		}

		this.validateStructure(child1);
		this.validateStructure(child2);
	}

	validateMetrics(int index)
	{
		if(index == NullNode)
		{
			return;
		}

		List<TreeNode> nodes = this._nodes;
		TreeNode node = nodes[index];
		
		int child1 = node.child1;
		int child2 = node.child2;

		if(node.isLeaf)
		{
			if(child1 != NullNode)
			{
				throw new StateError("Expected child1 to be null!");
			}
			if(child2 != NullNode)
			{
				throw new StateError("Expected child2 to be null!");
			}
			if(node.height != 0)
			{
				throw new StateError("Expected node's height to be 0!");
			}
			return;
		}

		if(child1 < 0 || child1 >= this._capacity)
		{				
			throw new RangeError.range(child1, 0, this._capacity, "child1", "Out of bounds!");
		}
		if(child2 < 0 || child2 >= this._capacity)
		{				
			throw new RangeError.range(child2, 0, this._capacity, "child2", "Out of bounds!");
		}

		int height1 = nodes[child1].height;
		int height2 = nodes[child2].height;
		int height;
		height = 1 + max(height1, height2);

		if(node.height != height)
		{
			throw new StateError("Expected node's height to be ${height}");
		}

		AABB aabb = AABB.combine(new AABB(), nodes[child1].BB, nodes[child2].BB);

		if(aabb[0] != node.BB[0] || aabb[1] != node.BB[1])
		{
			throw new StateError("Lower Bound is not equal!");
		}
		if(aabb[2] != node.BB[2] || aabb[3] != node.BB[3])
		{
			throw new StateError("Upper Bound is not equal!");
		}

		this.validateMetrics(child1);
		this.validateMetrics(child2);
	}

	void validate()
	{
		this.validateStructure(this._root);
		this.validateMetrics(this._root);

		int freeCount = 0;
		int freeIndex = this._freeNode;
		while(freeIndex != NullNode)
		{
			if(freeIndex < 0 || freeIndex >= this._capacity)
			{				
				throw new RangeError.range(freeIndex, 0, this._capacity, "freeIndex", "Out of bounds!");
			}
			freeIndex = this._nodes[freeIndex].next;
			++freeCount;
		}

		if(this.getHeight() != this.computeHeight(null))
		{
			throw new StateError("Expected height to match computed height.");
		}

		if(this._nodeCount + freeCount != this._capacity)
		{
			throw new AssertionError("Expected node count + free count to equal capactiy!");
		}
	}

	getMaxBalance()
	{
		int maxBalance = 0;
		int capacity = this._capacity;
		List<TreeNode> nodes = this._nodes;
		for(int i = 0; i < capacity; i++)
		{
			TreeNode node = nodes[i];
			if(node.height < 1)
			{
				continue;
			}
			
			if(node.isLeaf)
			{
				throw new StateError("Expected node not to be a leaf!");
			}

			int child1 = node.child1;
			int child2 = node.child2;
			int balance = (nodes[child2].height - nodes[child1].height).abs();
			maxBalance = max(maxBalance, balance);
		}

		return maxBalance;
	}

	T getUserdata(int proxyId)
	{
		return this._nodes[proxyId].userData;
	}

	AABB getFatAABB(int proxyId)
	{
		return this._nodes[proxyId].BB;
	}

	all(QueryCallback callback)
	{
		List<TreeNode> nodes = this._nodes;
		ListQueue stack = new ListQueue();
		stack.addLast(this._root);

		while(stack.length > 0)
		{
			int nodeId = stack.removeLast();
			if(nodeId == NullNode)
			{
				continue;
			}

			TreeNode node = nodes[nodeId];

			if(node.isLeaf)
			{
				bool proceed = callback(nodeId, node.userData);
				if(proceed == false)
				{
					return;
				}
			}
			else
			{
				stack.addLast(node.child1);
				stack.addLast(node.child2);
			}
		}
	}

	query(QueryCallback callback, AABB aabb)
	{
		List<TreeNode> nodes = this._nodes;
		ListQueue stack = new ListQueue();
		stack.addLast(this._root);

		while(stack.length > 0)
		{
			int nodeId = stack.removeLast();
			if(nodeId == NullNode)
			{
				continue;
			}

			TreeNode node = nodes[nodeId];

			if(testOverlap(node.BB, aabb))
			{
				if(node.isLeaf)
				{
					bool proceed = callback(nodeId, node.userData);
					if(proceed == false)
					{
						return;
					}
				}
				else
				{
					stack.addLast(node.child1);
					stack.addLast(node.child2);
				}
			}
		}
	}
}

bool testOverlap(AABB a, AABB b)
{
	double d1x = b[0] - a[2];
	double d1y = b[1] - a[3];

	double d2x = a[0] - b[2];
	double d2y = a[1] - b[3];

	// d1 = b.lowerBound - a.upperBound;
	// d2 = a.lowerBound - b.upperBound;

	if (d1x > 0.0 || d1y > 0.0)
	{
		return false;
	}

	if (d2x > 0.0 || d2y > 0.0)
	{
		return false;
	}

	return true;
}