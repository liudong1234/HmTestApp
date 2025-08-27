@Builder
export function HelloPageBuilder() {
  HellowWorldPage()
}
export class Message {
  value: string | undefined;
  constructor(value: string) {
    this.value = value;
  }
}

class BasicDataSource implements IDataSource {
  private listener: DataChangeListener | undefined = undefined;
  public dataArray: number[] = [];

  totalCount(): number {
    return this.dataArray.length;
  }

  getData(index: number): number {
    return this.dataArray[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    this.listener = listener;
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    this.listener = undefined;
  }
}

@Component
struct HellowWorldPage {
  @State message: string  = 'Hello World';
  @State pathStack: NavPathStack = new NavPathStack();
  private data: BasicDataSource = new BasicDataSource();

  aboutToAppear(): void {
    for (let index = 0; index < 20; index++) {
      this.data.dataArray.push(index);
    }
  }

  build() {
    NavDestination() {
      List() {
        LazyForEach(this.data, (item: number, index: number) => {
          ListItem() {
            ReuseComponent({ num: item })
          }
        }, (item: number, index: number) => index.toString())
      }.cachedCount(0)
    }
    .width('100%')
    .height('100%')
  }
}

@Reusable
@Component
struct ReuseComponent {
  @State num: number = 0;

  aboutToReuse(params: ESObject): void {
    this.num = params.num;
  }

  build() {
    Column() {
      Text('ReuseComponent num: ' + this.num.toString())
      ReuseComponentChild({num: this.num})
      Button('plus')
        .onClick(() => {
          this.num += 10;
        })
     }
     .height(200)
  }
}

@Component
struct ReuseComponentChild {
  @Link num: number;

  aboutToReuse(params: ESObject): void {
    setTimeout(() => {
      this.num = -1 * params.num;
    }, 1)
  }

  build() {
    Text('ReuseComponentChild num: ' + this.num.toString())
  }
}