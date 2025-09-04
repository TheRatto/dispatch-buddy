# Static Radar Layers Implementation Roadmap

## 🎯 **Goal: Bundle Static Layers Locally for Reliable Radar Display**

**Problem**: BOM transparency layers fail in low-data environments, causing broken radar display  
**Solution**: Bundle static layers (background, ranges, legend) in app assets for instant, reliable loading

---

## 📋 **Phase 1: Analysis & Planning**

### **1.1 Layer Analysis** 
- [ ] **Identify static vs dynamic layers**
  - ✅ Static: Background maps, range circles, legend  
  - ✅ Dynamic: Radar data, topography (sometimes)
- [ ] **Sample layer downloads** from multiple sites
- [ ] **Size analysis** per layer type
- [ ] **Quality assessment** (resolution, format)

### **1.2 Architecture Planning**
- [ ] **Asset directory structure** design
- [ ] **Naming convention** for local layers
- [ ] **Service layer updates** planning
- [ ] **Fallback strategy** design

---

## 📋 **Phase 2: Asset Collection**

### **2.1 Download Static Layers** ⬇️
**Critical layers to bundle:**
```
├── backgrounds/     # Coastlines, borders, geography
│   ├── IDR71.background.png   # Sydney
│   ├── IDR02.background.png   # Melbourne  
│   └── ...
├── ranges/         # Distance circles (64km, 128km, etc.)
│   ├── IDR71.range.png
│   ├── IDR02.range.png
│   └── ...
├── legends/        # Color scales
│   ├── IDR.legend.0.png       # Standard legend
│   └── IDR.legend.1.png       # Alternative legend
└── locations/      # City/town labels (optional - larger files)
    ├── IDR71.locations.png
    └── ...
```

### **2.2 Size Optimization**
- [ ] **PNG compression** optimization
- [ ] **Resolution analysis** (512x512 vs smaller)
- [ ] **File size targets** (<100KB per layer)
- [ ] **Total bundle size** estimation

---

## 📋 **Phase 3: Implementation**

### **3.1 Asset Integration**
- [ ] **Create assets/radar_layers/** directory
- [ ] **Add layer files** to Flutter assets
- [ ] **Update pubspec.yaml** asset declarations
- [ ] **Verify asset loading** with Flutter tooling

### **3.2 Service Layer Updates**
- [ ] **Update BomRadarService** layer URL logic:
  ```dart
  // OLD: Remote URLs
  backgroundUrl: 'https://www.bom.gov.au/products/radar_transparencies/IDR71.background.png'
  
  // NEW: Local assets with remote fallback  
  backgroundUrl: 'assets/radar_layers/backgrounds/IDR71.background.png'
  ```
- [ ] **Asset helper methods** for local layer paths
- [ ] **Fallback mechanism** to remote if local missing

### **3.3 RadarLayers Model Updates**
- [ ] **Support asset:// URLs** in RadarLayers
- [ ] **Image widget updates** for Asset vs Network loading
- [ ] **Error handling** for missing local assets

---

## 📋 **Phase 4: Testing & Optimization**

### **4.1 Functionality Testing**
- [ ] **Airplane mode testing** - verify radar works without internet
- [ ] **Layer compositing** - ensure proper stacking order
- [ ] **Performance testing** - asset loading vs network loading
- [ ] **Memory usage** analysis with bundled assets

### **4.2 Fallback Testing**
- [ ] **Missing asset** graceful degradation
- [ ] **Network recovery** when connection improves
- [ ] **Mixed mode** (local static + remote dynamic)

### **4.3 Size Impact**
- [ ] **App size increase** measurement
- [ ] **Download time impact** assessment  
- [ ] **Storage usage** on device

---

## 🎯 **Implementation Priority Order**

### **Quick Wins (Week 1)**
1. **Legend bundling** - Single file, immediate benefit
2. **Range circles** - Small files, universal benefit
3. **Major city backgrounds** - Sydney, Melbourne, Brisbane

### **Full Implementation (Week 2)**
4. **All site backgrounds** - Complete coverage
5. **Location labels** (if size permits)
6. **Optimization pass** - compression, cleanup

### **Polish (Week 3)**
7. **Asset management** - update system for new sites
8. **Documentation** - layer management guide
9. **Performance optimization** - lazy loading, caching

---

## 📊 **Success Metrics**

### **Reliability**
- ✅ **100% radar display** success in airplane mode
- ✅ **<2 second** initial load time with static layers
- ✅ **Zero layer failures** for bundled components

### **Performance**  
- ✅ **<50MB** total app size increase
- ✅ **<1 second** static layer load time
- ✅ **Smooth animation** with local layers

### **User Experience**
- ✅ **Professional appearance** regardless of connectivity
- ✅ **Instant feedback** on radar selection
- ✅ **Consistent quality** across all locations

---

## 🔧 **Technical Considerations**

### **Asset Management**
- **Automated download** script for layer collection
- **Version control** for layer updates
- **CI/CD integration** for asset updates

### **Flutter Integration**
- **Asset bundle** size optimization
- **Platform-specific** considerations (iOS/Android)
- **Memory management** for bundled images

### **Maintenance**  
- **BOM layer updates** monitoring
- **New site** addition process
- **Asset cleanup** for removed sites

---

## 📝 **Next Steps**

1. **Start with analysis** - download sample layers from 5 major sites
2. **Measure impact** - size, quality, load time
3. **Prototype integration** - test local asset loading
4. **Implement incrementally** - legend first, then expand
5. **Test thoroughly** - especially in low-connectivity scenarios

This roadmap will transform the radar feature from connectivity-dependent to reliable and professional! 🎯📡
