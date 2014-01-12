package away3d.tools.utils;

	//import away3d.arcane;
	import away3d.core.base.CompactSubGeometry;
	import away3d.core.base.ISubGeometry;
	import away3d.core.base.SkinnedSubGeometry;
	import away3d.core.base.SubMesh;
	
	//use namespace arcane;
	
	class GeomUtil
	{
		/**
		 * Build a list of sub-geometries from raw data vectors, splitting them up in
		 * such a way that they won't exceed buffer length limits.
		 */
		public static function fromVectors(verts:Array<Float>, indices:Array<UInt>, uvs:Array<Float>, normals:Array<Float>, tangents:Array<Float>, weights:Array<Float>, jointIndices:Array<Float>, triangleOffset:Int = 0):Array<ISubGeometry>
		{
			var LIMIT_VERTS:UInt = 3*0xffff;
			var LIMIT_INDICES:UInt = 15*0xffff;
			
			var subs:Array<ISubGeometry> = new Array<ISubGeometry>();
			
			if (uvs!=null && uvs.length==0)
				uvs = null;
			
			if (normals!=null && normals.length==0)
				normals = null;
			
			if (tangents!=null && tangents.length==0)
				tangents = null;
			
			if (weights!=null && weights.length==0)
				weights = null;
			
			if (jointIndices!=null && jointIndices.length==0)
				jointIndices = null;
			
			if ((indices.length >= LIMIT_INDICES) || (verts.length >= LIMIT_VERTS)) {
				var i:UInt, len:UInt, outIndex:UInt, j:UInt;
				var splitVerts:Array<Float> = new Array<Float>();
				var splitIndices:Array<UInt> = new Array<UInt>();
				var splitUvs:Array<Float> = (uvs != null)? new Array<Float>() : null;
				var splitNormals:Array<Float> = (normals != null)? new Array<Float>() : null;
				var splitTangents:Array<Float> = (tangents != null)? new Array<Float>() : null;
				var splitWeights:Array<Float> = (weights != null)? new Array<Float>() : null;
				var splitJointIndices:Array<Float> = (jointIndices != null)? new Array<Float>() : null;
				
				var mappings:Array<Int> = new Array<Int>();
				i = mappings.length;
				while (i-- > 0)
					mappings[i] = -1;
				
				var originalIndex:UInt;
				var splitIndex:UInt;
				var o0:UInt, o1:UInt, o2:UInt, s0:UInt, s1:UInt, s2:UInt,
					su:UInt, ou:UInt, sv:UInt, ov:UInt;
				// Loop over all triangles
				outIndex = 0;
				len = indices.length;
				
				// For loop conversion - 								for (i = 0; i < len; i += 3)
				
				for (i in 0...len) {
					splitIndex = splitVerts.length + 6;
					
					if (( (outIndex + 2) >= LIMIT_INDICES) || (splitIndex >= LIMIT_VERTS)) {
						subs.push(constructSubGeometry(splitVerts, splitIndices, splitUvs, splitNormals, splitTangents, splitWeights, splitJointIndices, triangleOffset));
						splitVerts = new Array<Float>();
						splitIndices = new Array<UInt>();
						splitUvs = (uvs != null)? new Array<Float>() : null;
						splitNormals = (normals != null)? new Array<Float>() : null;
						splitTangents = (tangents != null)? new Array<Float>() : null;
						splitWeights = (weights != null)? new Array<Float>() : null;
						splitJointIndices = (jointIndices != null)? new Array<Float>() : null;
						splitIndex = 0;
						j = mappings.length;
						while (j-- > 0)
							mappings[j] = -1;
						
						outIndex = 0;
					}
					
					// Loop over all vertices in triangle
					// For loop conversion - 					for (j = 0; j < 3; j++)
					for (j in 0...3) {
						
						originalIndex = indices[i + j];
						
						if (mappings[originalIndex] >= 0)
							splitIndex = mappings[originalIndex];
						
						else {
							
							o0 = originalIndex*3 + 0;
							o1 = originalIndex*3 + 1;
							o2 = originalIndex*3 + 2;
							
							// This vertex does not yet exist in the split list and
							// needs to be copied from the long list.
							splitIndex = Std.int(splitVerts.length/3);
							
							s0 = splitIndex*3 + 0;
							s1 = splitIndex*3 + 1;
							s2 = splitIndex*3 + 2;
							
							splitVerts[s0] = verts[o0];
							splitVerts[s1] = verts[o1];
							splitVerts[s2] = verts[o2];
							
							if (uvs!=null) {
								su = splitIndex*2 + 0;
								sv = splitIndex*2 + 1;
								ou = originalIndex*2 + 0;
								ov = originalIndex*2 + 1;
								
								splitUvs[su] = uvs[ou];
								splitUvs[sv] = uvs[ov];
							}
							
							if (normals!=null) {
								splitNormals[s0] = normals[o0];
								splitNormals[s1] = normals[o1];
								splitNormals[s2] = normals[o2];
							}
							
							if (tangents!=null) {
								splitTangents[s0] = tangents[o0];
								splitTangents[s1] = tangents[o1];
								splitTangents[s2] = tangents[o2];
							}
							
							if (weights!=null) {
								splitWeights[s0] = weights[o0];
								splitWeights[s1] = weights[o1];
								splitWeights[s2] = weights[o2];
							}
							
							if (jointIndices!=null) {
								splitJointIndices[s0] = jointIndices[o0];
								splitJointIndices[s1] = jointIndices[o1];
								splitJointIndices[s2] = jointIndices[o2];
							}
							
							mappings[originalIndex] = splitIndex;
						}
						
						// Store new index, which may have come from the mapping look-up,
						// or from copying a new set of vertex data from the original vector
						splitIndices[outIndex + j] = splitIndex;
					}
					
					outIndex += 3;
				}
				
				if (splitVerts.length > 0) {
					// More was added in the last iteration of the loop.
					subs.push(constructSubGeometry(splitVerts, splitIndices, splitUvs, splitNormals, splitTangents, splitWeights, splitJointIndices, triangleOffset));
				}
				
			} else
				subs.push(constructSubGeometry(verts, indices, uvs, normals, tangents, weights, jointIndices, triangleOffset));
			
			return subs;
		}
		
		/**
		 * Build a sub-geometry from data vectors.
		 */
		public static function constructSubGeometry(verts:Array<Float>, indices:Array<UInt>, uvs:Array<Float>, normals:Array<Float>, tangents:Array<Float>, weights:Array<Float>, jointIndices:Array<Float>, triangleOffset:Int):CompactSubGeometry
		{
			var sub:CompactSubGeometry;
			
			if (weights!=null && jointIndices!=null) {
				// If there were weights and joint indices defined, this
				// is a skinned mesh and needs to be built from skinned
				// sub-geometries.
				sub = new SkinnedSubGeometry(Std.int(weights.length/(verts.length/3)));
				cast(sub, SkinnedSubGeometry).updateJointWeightsData(weights);
				cast(sub, SkinnedSubGeometry).updateJointIndexData(jointIndices);
				
			} else
				sub = new CompactSubGeometry();
			
			sub.updateIndexData(indices);
			sub.fromVectors(verts, uvs, normals, tangents);
			return sub;
		}
		
		/*
		 * Combines a set of separate raw buffers into an interleaved one, compatible
		 * with CompactSubGeometry. SubGeometry uses separate buffers, whereas CompactSubGeometry
		 * uses a single, combined buffer.
		 * */
		public static function interleaveBuffers(numVertices:UInt, vertices:Array<Float> = null, normals:Array<Float> = null, tangents:Array<Float> = null, uvs:Array<Float> = null, suvs:Array<Float> = null):Array<Float>
		{
			
			var i:UInt =0 , compIndex:UInt = 0, uvCompIndex:UInt = 0, interleavedCompIndex:UInt = 0;
			var interleavedBuffer:Array<Float>;
			
			interleavedBuffer = new Array<Float>();
			
			/**
			 * 0 - 2: vertex position X, Y, Z
			 * 3 - 5: normal X, Y, Z
			 * 6 - 8: tangent X, Y, Z
			 * 9 - 10: U V
			 * 11 - 12: Secondary U V
			 */
			// For loop conversion - 			for (i = 0; i < numVertices; ++i)
			for (i in 0...numVertices) {
				uvCompIndex = i*2;
				compIndex = i*3;
				interleavedCompIndex = i*13;
				interleavedBuffer[ interleavedCompIndex     ] = vertices!=null? vertices[ compIndex       ] : 0;
				interleavedBuffer[ interleavedCompIndex + 1 ] = vertices!=null? vertices[ compIndex + 1   ] : 0;
				interleavedBuffer[ interleavedCompIndex + 2 ] = vertices!=null? vertices[ compIndex + 2   ] : 0;
				interleavedBuffer[ interleavedCompIndex + 3 ] = normals!=null? normals[   compIndex       ] : 0;
				interleavedBuffer[ interleavedCompIndex + 4 ] = normals!=null? normals[   compIndex + 1   ] : 0;
				interleavedBuffer[ interleavedCompIndex + 5 ] = normals!=null? normals[   compIndex + 2   ] : 0;
				interleavedBuffer[ interleavedCompIndex + 6 ] = tangents!=null? tangents[ compIndex       ] : 0;
				interleavedBuffer[ interleavedCompIndex + 7 ] = tangents!=null? tangents[ compIndex + 1   ] : 0;
				interleavedBuffer[ interleavedCompIndex + 8 ] = tangents!=null? tangents[ compIndex + 2   ] : 0;
				interleavedBuffer[ interleavedCompIndex + 9 ] = uvs!=null? uvs[          uvCompIndex     ] : 0;
				interleavedBuffer[ interleavedCompIndex + 10 ] = uvs!=null? uvs[          uvCompIndex + 1 ] : 0;
				interleavedBuffer[ interleavedCompIndex + 11 ] = suvs!=null? suvs[          uvCompIndex      ] : 0;
				interleavedBuffer[ interleavedCompIndex + 12 ] = suvs!=null? suvs[          uvCompIndex + 1 ] : 0;
			}
			
			return interleavedBuffer;
		}
		
		/*
		 * returns the subGeometry index in its parent mesh subgeometries vector
		 */
		public static function getMeshSubgeometryIndex(subGeometry:ISubGeometry):UInt
		{
			var index:UInt = 0;
			var subGeometries:Array<ISubGeometry> = subGeometry.parentGeometry.subGeometries;
			// For loop conversion - 			for (var i:UInt = 0; i < subGeometries.length; ++i)
			var i:UInt = 0;
			for (i in 0...subGeometries.length) {
				if (subGeometries[i] == subGeometry) {
					index = i;
					break;
				}
			}
			
			return index;
		}
		
		/*
		 * returns the subMesh index in its parent mesh subMeshes vector
		 */
		public static function getMeshSubMeshIndex(subMesh:SubMesh):UInt
		{
			var index:UInt = 0;
			var subMeshes:Array<SubMesh> = subMesh.parentMesh.subMeshes;
			// For loop conversion - 			for (var i:UInt = 0; i < subMeshes.length; ++i)
			var i:UInt = 0;
			for (i in 0...subMeshes.length) {
				if (subMeshes[i] == subMesh) {
					index = i;
					break;
				}
			}
			
			return index;
		}
	}
