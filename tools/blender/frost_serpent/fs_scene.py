# Preview stage: sunny pen-like lighting, grass ground, camera helper (Roblox coordinates).
def setup_stage(ground_hex="5DAE4A"):
    sc = bpy.context.scene
    for nm in ("Cube", "Light", "Camera"):
        ob = bpy.data.objects.get(nm)
        if ob:
            bpy.data.objects.remove(ob, do_unlink=True)
    st = bpy.data.collections.get("Stage")
    if st is None:
        st = bpy.data.collections.new("Stage")
        sc.collection.children.link(st)
    for ob in list(st.objects):
        bpy.data.objects.remove(ob, do_unlink=True)
    world = sc.world or bpy.data.worlds.new("World")
    sc.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    bg.inputs["Color"].default_value = (0.42, 0.66, 0.95, 1)
    bg.inputs["Strength"].default_value = 0.9
    sun_d = bpy.data.lights.new("Sun", "SUN")
    sun_d.energy = 4.0
    sun_d.angle = math.radians(6)
    sun = bpy.data.objects.new("Sun", sun_d)
    st.objects.link(sun)
    sun.rotation_euler = (math.radians(50), math.radians(10), math.radians(-35))
    gm = bpy.data.meshes.new("Ground")
    bm = bmesh.new()
    bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=60)
    bm.to_mesh(gm)
    bm.free()
    g = bpy.data.objects.new("Ground", gm)
    st.objects.link(g)
    g.active_material = get_mat(ground_hex, "SmoothPlastic", 0)
    cam_d = bpy.data.cameras.new("Cam")
    cam_d.lens = 50
    cam = bpy.data.objects.new("Cam", cam_d)
    st.objects.link(cam)
    sc.camera = cam
    try:
        sc.render.engine = "BLENDER_EEVEE"
    except TypeError:
        sc.render.engine = "BLENDER_EEVEE_NEXT"
    sc.view_settings.view_transform = "Standard"
    sc.render.film_transparent = False
    try:
        sc.eevee.taa_render_samples = 32
        sc.eevee.use_shadows = True
    except Exception:
        pass


def shoot(path, eye, target, res=(1600, 900), lens=50):
    sc = bpy.context.scene
    cam = sc.camera
    cam.data.lens = lens
    e, t = C3 @ Vector(eye), C3 @ Vector(target)
    cam.location = e
    cam.rotation_euler = (t - e).to_track_quat("-Z", "Y").to_euler()
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.render.resolution_percentage = 100
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)


def label(name, text, pos, size=0.8, hx="1B2238"):
    st = bpy.data.collections["Stage"]
    old = bpy.data.objects.get(name)
    if old:
        bpy.data.objects.remove(old, do_unlink=True)
    cu = bpy.data.curves.new(name, "FONT")
    cu.body = text
    cu.size = size
    cu.align_x = "CENTER"
    ob = bpy.data.objects.new(name, cu)
    st.objects.link(ob)
    ob.location = C3 @ Vector(pos)
    ob.rotation_euler = (math.radians(70), 0, math.radians(180))
    ob.active_material = get_mat(hx, "SmoothPlastic", 0)
    return ob


def only(names):
    for c in bpy.data.collections:
        if c.name.startswith("FS_"):
            c.hide_render = c.name not in names


def sheet(paths, cols, out, bg=(1, 1, 1, 1)):
    """Contact sheet of equal-size renders (row-major, top-left first) via numpy."""
    import numpy as np
    imgs = []
    for p in paths:
        im = bpy.data.images.load(p, check_existing=False)
        w, h = im.size
        a = np.empty(w * h * 4, dtype=np.float32)
        im.pixels.foreach_get(a)
        imgs.append(a.reshape(h, w, 4))
        bpy.data.images.remove(im)
    h, w = imgs[0].shape[:2]
    rows = (len(imgs) + cols - 1) // cols
    canvas = np.ones((rows * h, cols * w, 4), dtype=np.float32) * np.array(bg, dtype=np.float32)
    for k, a in enumerate(imgs):
        r, c = divmod(k, cols)
        y0 = (rows - 1 - r) * h  # Blender pixels start bottom-left
        canvas[y0 : y0 + h, c * w : (c + 1) * w] = a
    out_im = bpy.data.images.new("sheet", cols * w, rows * h, alpha=True)
    out_im.pixels.foreach_set(canvas.ravel())
    out_im.filepath_raw = out
    out_im.file_format = "PNG"
    out_im.save()
    bpy.data.images.remove(out_im)
