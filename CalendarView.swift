//
//  CalendarView.swift
//  Sunshine
//
//  Created by Sunshine Days on 2022/1/23.
//

import Foundation

/// 屏宽
let kScreenWidth: CGFloat = UIScreen.main.bounds.size.width

class CalendarView: UIView {

    private lazy var weekView: UIView = {
        let view = UIView()
        
        return view
    }()
    
    private lazy var flowLayout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        return flowLayout
    }()
    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = false
        collectionView.isPagingEnabled = true
        collectionView.scrollsToTop = false
        collectionView.register(CalendarCell.self, forCellWithReuseIdentifier: "CalendarCell")
        return collectionView
    }()
    
    private let cellSize: CGSize = .init(width: kScreenWidth / 7, height: kScreenWidth / 7)
        
    private var offset = 0
    
    /// 选中的时间戳
    private var selectedTime = Date().timeIntervalSince1970 {
        didSet {
            selectedTimeBlock?(showTime)
        }
    }

    /// 展示的月份的时间（当月1号的时间戳）
    private var showTime: Double = Date().timeIntervalSince1970 {
        didSet {
            showMonthBlock?(showTime)
        }
    }
    
    /// 当前是否展示
    private var isShow = true
    
    var selectedTimeBlock: ((_ time: Double) -> Void)?
    var showMonthBlock: ((_ time: Double) -> Void)?
    
    func last() {
        setMonth(offset: offset - 1)
    }
    
    func next() {
        setMonth(offset: offset + 1)
    }
    
    func setMonth(offset: Int) {
        self.offset = offset
        initModels(offset: offset)
    }
    
    /// 收起来
    func lessen() {
        if isShow {
            show()
        }
    }
    
    /// 展示/不展示
    func show() {
        isShow = !isShow
        if isShow {
            self.collectionView.snp.remakeConstraints { make in
                make.top.equalTo(self.weekView.snp.bottom)
                make.leading.trailing.bottom.equalToSuperview()
                make.height.equalTo(self.cellSize.height * CGFloat(self.models.count / 7 + (self.models.count % 7 > 0 ? 1 : 0)))
                self.layoutIfNeeded()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
                guard let self = self else { return }
                self.collectionView.scrollToItem(at: .init(row: 0, section: 0), at: .top, animated: true)
            }

        } else {
            self.collectionView.snp.remakeConstraints { make in
                make.top.equalTo(self.weekView.snp.bottom)
                make.leading.trailing.bottom.equalToSuperview()
                make.height.equalTo(self.cellSize.height)
                self.layoutIfNeeded()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
                guard let self = self else { return }
                if let index = self.models.firstIndex(where: { $0.isSelected }) {
                    self.collectionView.scrollToItem(at: .init(row: index, section: 0), at: .top, animated: true)
                } else {
                    self.initModels(offset: 0)
                    let index = models.firstIndex(where: { $0.isToday }) ?? 0
                    self.collectionView.scrollToItem(at: .init(row: index, section: 0), at: .top, animated: true)
                }
            }
        }
    }
    
    private var models = [CalendarModel]() {
        didSet {
            collectionView.reloadData()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(weekView)
        weekView.snp.makeConstraints { make in
            make.top.equalTo(0)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(20)
        }
        
        let titles = ["日", "一", "二", "三", "四", "五", "六"]
        for (i, title) in titles.enumerated() {
            let label = UILabel(frame: .init(x: cellSize.width * CGFloat (i % 7), y: 0, width: cellSize.width, height: 20))
            label.set(title, textColor: UIColor.gray, font: UIFont.systemFont(ofSize: 14), textAlignment: .center)
            weekView.addSubview(label)
        }
        
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(weekView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(cellSize.height)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}

extension CalendarView {
    // 获取界面数据
    private func initModels(offset: Int) {
        let calendar = Calendar.current
        
        // 获取当前月
        var firstTimeComponents = DateComponents()
        firstTimeComponents.month = offset
        var firstDate = calendar.date(byAdding: firstTimeComponents, to: Date()) ?? Date()
        firstTimeComponents = calendar.dateComponents([.year, .month], from: firstDate)
        // 获取当前月1号
        firstDate = calendar.date(from: firstTimeComponents) ?? Date()
        let firstTime = firstDate.timeIntervalSince1970
        
        showTime = firstTime
        
        // 获取当前月的信息
        let components = calendar.dateComponents([.year, .month, .day, .weekday], from: firstDate)
        guard let year = components.year else { return }
        guard let month = components.month else { return }
        // 获取1号是星期几 星期天是1，星期一是2，以此类推
        guard let weekday = calendar.dateComponents([.weekday], from: firstDate).weekday else { return }
        // 获取一个月有多少天
        guard let monthCount = calendar.range(of: .day, in: .month, for: firstDate)?.count else { return }
        
        // 今天
        let currentcompoents = calendar.dateComponents([.year, .month, .day], from: Date())
        guard let curretnYear = currentcompoents.year else { return }
        guard let currentMonth = currentcompoents.month else { return }
        guard let currentDay = currentcompoents.day else { return }
        
        var list = [CalendarModel]()
        // 给1号前补位空数据
        for _ in 0 ..< (weekday - 1) % 7 {
            var model = CalendarModel()
            model.time = 0
            list.append(model)
        }

        for i in 1 ... monthCount {
            var model = CalendarModel()
            model.time = firstTime + Double(i - 1) * 24 * 60 * 60
            model.day = i
            model.isToday = year == curretnYear && month == currentMonth && currentDay == i
            model.isSelected = model.isToday
            model.isElective = true
            list.append(model)
        }
        models = list
    }
}

extension CalendarView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return models.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CalendarCell", for: indexPath) as! CalendarCell
        cell.model = models[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return cellSize
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
        
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if models[indexPath.row].time == 0 { return }
        
        if let index = models.firstIndex(where: { $0.isSelected }) {
            models[index].isSelected = false
        }
        models[indexPath.row].isSelected = true
        
        selectedTime = models[indexPath.row].time
    }
    
}


fileprivate class CalendarCell: BaseCollectionViewCell {
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        label.backgroundColor = .red
        label.layer.cornerRadius = 15
        return label
    }()
    
    private lazy var dotView: UIView = {
        let view = UIView()
        view.backgroundColor = .red
        view.layer.cornerRadius = 1.5
        return view
    }()
    
    var model: CalendarModel! {
        didSet {
            titleLabel.text = "\(model.day)"
            titleLabel.textColor = model.textColor
            titleLabel.layer.backgroundColor = model.backgroundColor.cgColor
            titleLabel.layer.borderWidth = model.borderWidth
            titleLabel.borderColor = .red
            
            dotView.isHidden = !model.isElective
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(30)
        }
        
        contentView.addSubview(dotView)
        dotView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.height.equalTo(3)
            make.bottom.equalTo(-2)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


/// 日历model
fileprivate struct CalendarModel {
    /// 时间戳
    var time: Double = 0.0
    /// 天
    var day: Int = 0
    /// 是否是今天
    var isToday = false
    /// 是否选中
    var isSelected = false
    /// 是否可选
    var isElective = false
    
    var textColor: UIColor {
        if time == 0 {
            return UIColor.clear
        }
        if isSelected {
            return UIColor.white
        }
        return .black
    }
    
    var backgroundColor: UIColor {
        if isSelected {
            return .red
        }
        return .clear
    }
    
    var borderWidth: CGFloat {
        if isToday || isSelected {
            return 1
        }
        return 0
    }
}
